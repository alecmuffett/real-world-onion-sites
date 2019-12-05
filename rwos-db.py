#!/usr/bin/env python3
from datetime import datetime, timezone
from multiprocessing import Pool, Lock
import csv
import datetime as dt
import sqlite3
import subprocess
import sys
import time

GLOBAL_DB = None # has to be a global because pickling :-(

MASTER_CSV = 'master.csv'
DB_FILENAME = 'fetch.sqlite3'
SOCKS_PROXY = 'socks5h://127.0.0.1:9150/'
USER_AGENT = 'Mozilla/5.0 (Windows NT 6.1; rv:60.0) Gecko/20100101 Firefox/60.0'
BADNESS = 900
CURL_TIMEOUT = 120
RETRY_SLEEP = 60
RETRY_LIMIT = 6
PLACEHOLDER = '-'
POOL_WORKERS = 10
DETECTOR_HISTORY=14
YES = 'y'

DEFERRED_CATEGORIES = ( # stuff to push down the page due to size
    'globaleaks',
    'securedrop for individuals',
    'securedrop for organisations',
)

EMOJI_HTTP = ':wrench:'
EMOJI_HTTPS = ':closed_lock_with_key:'
EMOJI_UNSET = ':question:'
EMOJI_2xx = ':white_check_mark:'
EMOJI_3xx = ':eight_spoked_asterisk:'
EMOJI_4xx = ':no_entry_sign:'
EMOJI_5xx = ':stop_sign:'
EMOJI_DEAD = ':sos:'
EMOJI_NO_DATA = ':new:'

H1 = '#'
H2 = '##'
H3 = '###'
H4 = '####'
B = '*'
BB = '  *'
BBB = '    *'
LINE = '----'

SCHEMA_SQL = '''
PRAGMA journal_mode = wal;
PRAGMA foreign_keys = ON;
PRAGMA encoding = "UTF-8";
BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS fetches (
    id INTEGER PRIMARY KEY NOT NULL,
    ctime INTEGER DEFAULT (CAST(strftime('%s','now') AS INTEGER)) NOT NULL,
    run TEXT NOT NULL,
    url TEXT NOT NULL,
    attempt INTEGER NOT NULL,
    http_code INTEGER NOT NULL,
    curl_exit INTEGER NOT NULL,
    out TEXT NOT NULL,
    err TEXT NOT NULL
    );
PRAGMA user_version = 1;
COMMIT;
'''

INSERT_SQL = '''
INSERT INTO
fetches (run, url, attempt, out, err, http_code, curl_exit)
VALUES (:run, :url, :attempt, :out, :err, :http_code, :curl_exit)
'''

SUMMARY_SQL = '''
SELECT foo.ctime, foo.attempt, foo.http_code, foo.curl_exit
FROM fetches foo
INNER JOIN (
  SELECT url, run, MAX(attempt) AS pivot
  FROM fetches
  WHERE url = :url
  GROUP BY url, run
) bar
ON foo.url = bar.url
AND foo.run = bar.run
AND foo.attempt = bar.pivot
ORDER BY ctime DESC
LIMIT :limit
'''

def extract_hcode(s): # static
    if s == None:
        return BADNESS + 1
    lines = s.splitlines()
    if len(lines) == 0:
        return BADNESS + 2
    fields = lines[0].split()
    if len(fields) < 2:
        return BADNESS + 3
    try:
        code = int(fields[1])
    except:
        code = BADNESS + 4
    return code

class Database:
    def __init__(self, filename):
        self.connection = sqlite3.connect(filename)
        self.connection.text_factory = lambda x: unicode(x, UTF8, 'ignore') # ignore bad unicode shit
        self.cursor = self.connection.cursor()
        self.cursor.executescript(SCHEMA_SQL)
        self.now = time.strftime('%Y%m%d%H%M%S', time.gmtime())
        self.lock = Lock()

    def commit(self):
        self.connection.commit()

    def close(self):
        self.commit()
        self.connection.close()

    def summary(self, url, limit=DETECTOR_HISTORY):
        params = { 'url': url, 'limit': limit }
        rows = self.cursor.execute(SUMMARY_SQL, params)
        return rows.fetchall()

    def insert(self, rowhash):
        rowhash['run'] = self.now
        self.lock.acquire() # BEGIN PRIVILEGED CODE
        self.cursor.execute(INSERT_SQL, rowhash)
        self.commit()
        self.lock.release() # END PRIVILEGED CODE

class URL:
    def __init__(self, url):
        if not (url.startswith('http://') or url.startswith('https://')):
            raise RuntimeError('not a proper url: ' + url)
        self.url = url
        self.attempt = 0
        self.last_code = None

    def fetch1(self):
        args = [ 'curl', '--head', '--user-agent', USER_AGENT, '--proxy', SOCKS_PROXY, self.url ]
        time.sleep(1) # slight breathing space because MP
        try:
            p = subprocess.Popen(args, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE) # todo: text=True
            (out, err) = p.communicate(timeout=CURL_TIMEOUT)
            hcode = extract_hcode(str(out)) # str() not needed if text=True
            if hcode == 200: err = PLACEHOLDER
            ecode = p.returncode
        except subprocess.TimeoutExpired as e:
            (out, err) = (PLACEHOLDER, str(e))
            hcode = BADNESS + 10
            ecode = BADNESS + 10
        self.last_code = hcode
        self.attempt += 1
        GLOBAL_DB.insert(dict(
            url=self.url,
            attempt=self.attempt,
            out=out,
            err=err,
            http_code=hcode,
            curl_exit=ecode,
        ))

    def fetchwrap(self):
        for i in range(RETRY_LIMIT):
            self.fetch1()
            print('try{0}: {1} {2}'.format(i, self.url, self.last_code))
            if self.last_code < BADNESS: return
            time.sleep(RETRY_SLEEP)

def placeholder(s):
    if s == '': return PLACEHOLDER
    if s == None: return PLACEHOLDER
    return s

def caps(s):
    return ' '.join([w.capitalize() for w in s.lower().split()])

def deferred(s):
    return s in DEFERRED_CATEGORIES

def get_categories(chunk):
    src = sorted(set([x['category'] for x in chunk]))
    dst = [ x for x in src if not deferred(x) ]
    dst.extend([ x for x in src if deferred(x) ])
    return dst

def get_placeholder(row, k):
    return placeholder(row.get(k, ''))

def sort_using(chunk, k):
    return sorted(chunk, key=lambda x: x[k])

def grep_using(chunk, k, v, invert=False):
    if invert:
        return [ x for x in chunk if x.get(k, '') != v ]
    else:
        return [ x for x in chunk if x.get(k, '') == v ]

def get_proof(row):
    url = get_placeholder(row, 'proof_url')
    if url == '-': return 'to be done'
    if url == 'ssl': return 'see tls/ssl certificate'
    return '[link]({})'.format(url)

def get_summary(url):
    rows = GLOBAL_DB.summary(url)
    if len(rows) == 0:
        return ( EMOJI_NO_DATA, )
    result = []
    for when, attempt, hcode, ecode in rows:
        emoji = EMOJI_UNSET
        if hcode >= 200 and hcode < 300:
            emoji = EMOJI_2xx
        elif hcode >= 300 and hcode < 400:
            emoji = EMOJI_3xx
        elif hcode >= 400 and hcode < 500:
            emoji = EMOJI_4xx
        elif hcode >= 500 and hcode < 600:
            emoji = EMOJI_5xx
        elif hcode >= BADNESS:
            emoji = EMOJI_DEAD
        t = datetime.fromtimestamp(when, timezone.utc)
        result.append('<span title="attempts={1} code={2} exit={3} time={4}">{0}</span>'.format(emoji, attempt, hcode, ecode, t))
    return result

def print_chunk(chunk, title, description=None, print_bar=True):
    print(LINE)
    print(H2, caps(title))
    print()
    if description:
        print(description)
        print()
    for row in sort_using(chunk, 'site_name'):
        url = row['onion_url']
        padlock = EMOJI_HTTPS if url.startswith('https') else EMOJI_HTTP
        print(H3, '[{site_name}]({onion_url})'.format(**row), padlock)
        comment = get_placeholder(row, 'comment')
        if comment != '-': print('*{}*'.format(comment))
        # linky-linky, with https-emoji
        print(B, 'link: [{0}]({0})'.format(url))
        # apparently some people like copying and pasting plain text
        print(B, 'plain: `{0}`'.format(url))
        # print proof unconditionally, as encouragement to fix it
        print(B, 'proof: {0}'.format(get_proof(row)))
        if print_bar:
            bar = ''.join(get_summary(url))
            print(B, 'check:', bar)
        print()

def poolhook(x):
    x.fetchwrap()

def do_fetch(master):
    chunk = grep_using(master, 'flaky', YES, invert=True)
    work = [ URL(x['onion_url']) for x in chunk ]
    with Pool(POOL_WORKERS) as p: p.map(poolhook, work)

def print_index(cats):
    print(LINE)
    print(H1, 'Index')
    print()
    for cat in cats:
        print(B, '[{0}](#{1})'.format(caps(cat), cat.lower().replace(' ', '-')))
    print()

def do_print(master):
    cats = get_categories(master)
    print_index(cats)
    for cat in cats:
        chunk = grep_using(master, 'category', cat)
        chunk = grep_using(chunk, 'flaky', YES, invert=True)
        print_chunk(chunk, cat)
    flaky = grep_using(master, 'flaky', YES)
    print_chunk(flaky, 'Flaky Sites', description='These sites have apparently stopped responding.', print_bar=False)

if __name__ == '__main__':
    master = None

    # csv: category, site_name, flaky, onion_url, comment, proof_url
    with open(MASTER_CSV, 'r') as fh:
        dr = csv.DictReader(fh)
        master = [ x for x in dr ]

    GLOBAL_DB = Database(DB_FILENAME)

    for arg in sys.argv[1:]:
        if arg == 'fetch': do_fetch(master)
        if arg == 'print': do_print(master)

    GLOBAL_DB.close()
