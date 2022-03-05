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
    if not fields: continue
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
    dates = 'date={0} not_before={1} not_after={2}'.format(r['at'], r['nb'], r['na'])
    sans = r['cn'].split()
    sans.extend(r['san'].split())
    ca_data = [ x.strip() for x in r['in'].lower().split(',') ]
    ca_data.append('cn=BAD OR MISSING CN FIELD IN CT LOG')
    ca = [x for x in ca_data if x.startswith('cn=')][0][3:]
    for san in sans:
        if not onion_re.search(san): continue
        if done.get(san, False): continue
        done[san] = True
        is_wildcard = True if re.match(r'\*', san) else False
        if is_wildcard:
            print('* `{}`'.format(san))
        else:
            print('* [`{san}`](https://{san}) [eotk?](https://{san}/hello-onion/)'.format(san=san))
        print('  * {0}'.format(dates))
        print('  * **{0}**'.format(ca))
