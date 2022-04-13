#!/usr/bin/env python3
from datetime import datetime, timezone
from multiprocessing import Pool, Lock
import csv
import datetime as dt
import re
import sqlite3
import subprocess
import sys
import time

GLOBAL_DB = None # has to be a global because pickling :-(

MASTER_CSV = 'master.csv'
SECUREDROP_CSV = 'securedrop-api.csv'
DB_FILENAME = 'fetch.sqlite3'
SOCKS_PROXY = 'socks5h://127.0.0.1:9050/'
USER_AGENT = 'Mozilla/5.0 (Windows NT 6.1; rv:60.0) Gecko/20100101 Firefox/60.0'
BADNESS = 900
CURL_TIMEOUT = 120
RETRY_SLEEP = 60
RETRY_LIMIT = 6
PLACEHOLDER = '-'
POOL_WORKERS = 10
DETECTOR_HISTORY=14
TRUE_STRING = 'TRUE'
FOOTNOTES = 'Footnotes'

DEFERRED_CATEGORIES = ( # stuff to push down the page due to size
    'Globaleaks',
    'SecureDrop',
)

EMOJI_HTTP = ':small_red_triangle: **HTTP**'
EMOJI_HTTPS = ':closed_lock_with_key: **HTTPS**'
EMOJI_UNSET = ':question:'
EMOJI_2xx = ':white_check_mark:'
EMOJI_3xx = ':eight_spoked_asterisk:'
EMOJI_4xx = ':no_entry_sign:'
EMOJI_5xx = ':stop_sign:'
EMOJI_BAD_CERT = ':key:'
EMOJI_DEAD = ':sos:'
EMOJI_NO_CONN = ':exclamation:'
EMOJI_NO_DATA = ':new:'
EMOJI_NO_DESC = ':question:'
EMOJI_CONN_TIMEOUT = ':alarm_clock:'
EMOJI_TTL_TIMEOUT = ':timer_clock:'

H1 = '#'
H2 = '##'
H3 = '###'
H4 = '####'
B = '*'
BB = '  *'
BBB = '    *'
LINE = '----'
INDEXJUMP = ':arrow_up: [return to top index](#index)'

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
SELECT foo.ctime, foo.attempt, foo.http_code, foo.curl_exit, foo.err
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

TRASH_SQL = '''
DELETE
FROM fetches
WHERE ctime < (CAST(strftime('%s', (SELECT DATETIME('now', '-30 day'))) AS INTEGER));
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

def placeholder(s):
    if s == '': return PLACEHOLDER
    if s == None: return PLACEHOLDER
    return s

def unicode_cleanup(x):
    x = placeholder(x) # canonicalise blanks and None
    if isinstance(x, str): # native python3 utf-8 string
        result = x
    else: # is byte array
        result = x.decode('utf-8', 'ignore')
    return result

class Database:
    def __init__(self, filename):
        self.connection = sqlite3.connect(filename)
        self.connection.text_factory = lambda x: unicode_cleanup(x)
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

    def trash(self):
        self.lock.acquire() # BEGIN PRIVILEGED CODE
        result = self.cursor.execute(TRASH_SQL)
        self.commit()
        self.lock.release() # END PRIVILEGED CODE
        return result.fetchall()

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
    if url == '-': return ':crystal_ball: to be confirmed'
    if url == 'tbc': return ':crystal_ball: to be confirmed'
    if url == 'ssl': return ':lock: see tls/ssl certificate'
    if url == 'header': return ':mag: see onion-location header'
    return '[link]({})'.format(url)

def get_summary(url):
    rows = GLOBAL_DB.summary(url)
    if len(rows) == 0:
        return ( EMOJI_NO_DATA, )
    result = []
    for when, attempt, hcode, ecode, errstr in rows:
        errstr = unicode_cleanup(errstr) # THIS SHOULD NOT BE NEEDED, WHY? PERHAPS BECAUSE MULTI-LINE?
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
            emoji = EMOJI_DEAD # default
            if 'SSL certificate' in errstr:
                emoji = EMOJI_BAD_CERT
            elif 'timed out' in errstr:
                emoji = EMOJI_CONN_TIMEOUT
            elif "Can't complete SOCKS5 connection" in errstr:
                # todo: parse out socks error codes from https://datatracker.ietf.org/doc/html/rfc1928#section-6
                if re.search(r'\(1\)$', errstr):
                    emoji = EMOJI_NO_CONN
                elif re.search(r'\(4\)$', errstr):
                    emoji = EMOJI_NO_DESC
                elif re.search(r'\(6\)$', errstr):
                    emoji = EMOJI_TTL_TIMEOUT
        t = datetime.fromtimestamp(when, timezone.utc)
        result.append('<span title="attempts={1} code={2} exit={3} time={4}">{0}</span>'.format(emoji, attempt, hcode, ecode, t))
    return result

def print_chunk(chunk, title, description=None, print_bar=True):
    print(LINE)
    print(H2, title) # was: caps(title)
    print()
    if description:
        print(description)
        print()
    for row in sort_using(chunk, 'site_name'):
        url = row['onion_url']
        padlock = EMOJI_HTTPS if url.startswith('https') else EMOJI_HTTP
        print(H3, '[{site_name}]({onion_url})'.format(**row))
        comment = get_placeholder(row, 'comment')
        if comment != '-': print('*{}*'.format(comment))
        # short name
        oname = row['onion_name']
        if oname != '': print(B, 'short: `{0}`'.format(oname))
        # transport
        print(B, 'transport:', padlock)
        # linky-linky
        print(B, 'link: [{0}]({0})'.format(url))
        # apparently some people like copying and pasting plain text
        print(B, 'plain: `{0}`'.format(url))
        # print proof unconditionally, as encouragement to fix it
        print(B, 'proof: {0}'.format(get_proof(row)))
        if print_bar:
            bar = ''.join(get_summary(url))
            print(B, 'check:', bar)
        print()
    print(INDEXJUMP)
    print()

def poolhook(x):
    x.fetchwrap()

def do_fetch(master):
    chunk = grep_using(master, 'flaky', TRUE_STRING, invert=True)
    work = [ URL(x['onion_url']) for x in chunk ]
    with Pool(POOL_WORKERS) as p: p.map(poolhook, work)

def print_index(cats):
    print(LINE)
    print(H1, 'Index')
    print()
    for cat in cats:
        print(B, '[{0}](#{1})'.format(cat, # was: caps(cat)
                                      cat.lower().replace(' ', '-')))
    print(B, '[{0}](#{1})'.format(FOOTNOTES, FOOTNOTES.lower()))
    print()

def do_print(master):
    cats = get_categories(master)
    print_index(cats)
    for cat in cats:
        chunk = grep_using(master, 'category', cat)
        chunk = grep_using(chunk, 'flaky', TRUE_STRING, invert=True)
        print_chunk(chunk, cat)
    flaky = grep_using(master, 'flaky', TRUE_STRING)
    print_chunk(flaky, 'Flaky Sites', description='These sites have apparently stopped responding.', print_bar=False)

def do_trash():
    for x in GLOBAL_DB.trash():
        print('trash:', x)

if __name__ == '__main__':
    master = None

    with open(MASTER_CSV, 'r') as fh:
        dr = csv.DictReader(fh)
        master = [ x for x in dr ]

    with open(SECUREDROP_CSV, 'r') as fh:
        dr = csv.DictReader(fh)
        master.extend([ x for x in dr ])

    GLOBAL_DB = Database(DB_FILENAME)

    for arg in sys.argv[1:]:
        if arg == 'fetch': do_fetch(master)
        if arg == 'print': do_print(master)
        if arg == 'trash': do_trash()

    GLOBAL_DB.close()
