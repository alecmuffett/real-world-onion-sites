#!/usr/bin/env python3

import re
import csv
import pprint
import requests
from bs4 import BeautifulSoup

url = 'https://crt.sh/?dNSName=%25.onion&exclude=expired&match=ILIKE'
session = requests.Session()
response = session.get(url)
results = []
onion_re = re.compile(r'[2-7a-z]{56}\.onion(\s|$)')

status = response.status_code
if status != 200: raise RuntimeError('http status: {}'.format(status))

html_doc = response.text
soup = BeautifulSoup(html_doc, 'html.parser')

table = soup.find_all('table')[2]
table_rows = table.find_all('tr')

for tr in table_rows: # skip header
    for br in tr.find_all("br"): br.replace_with(" ")
    td = tr.find_all('td')
    fields = [i.text for i in td]
    if not fields:
        continue
    result = dict()
    result['id'] = fields[0]
    result['at'] = fields[1]
    result['nb'] = fields[2]
    result['na'] = fields[3]
    result['cn'] = fields[4]
    result['san'] = fields[5]
    result['in'] = fields[6]
    results.append(result)

done = dict()
for r in results:
    # pprint.pprint(r)
    stamps = '{0} nb={1} na={2}'.format(r['at'], r['nb'], r['na'])
    sans = r['cn'].split()
    sans.extend(r['san'].split())
    for san in sans:
        if not onion_re.search(san): continue
        if done.get(san, False): continue
        done[san] = True
        if re.match(r'\*', san):
            print('* `{san}`\n  * {when}'.format(san=san, when=stamps))
        else:
            url = 'https://' + san
            print('* [`{url}`]({url})\n  * {when}'.format(url=url, when=stamps))
