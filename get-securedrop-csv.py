#!/usr/bin/env python3

import csv
import pprint
import json
import requests
import html

output_csv = 'securedrop-api.csv'
sd_url = 'https://securedrop.org/api/v1/directory/'
fieldnames = "flaky category site_name onion_name onion_url proof_url comment".split()

def xx(thing, key):
    val = thing.get(key, None) or '' # catches instance where key=existing and val=None
    return html.escape(val)

def push(stack, entry):
    method = 'http' # this needs some discussion with Securedrop
    result = dict()
    result['flaky'] = ''
    result['category'] = 'SecureDrop'
    result['site_name'] = xx(entry, 'title')
    result['onion_url'] = '{0}://{1}'.format(method, xx(entry, 'onion_address'))
    result['onion_name'] = xx(entry, 'onion_name')
    result['proof_url'] = xx(entry, 'landing_page_url')
    result['comment'] = 'via: {}'.format(sd_url)
    stack.append(result)

if __name__ == '__main__':
    session = requests.Session()
    response = session.get(sd_url)
    data = response.json()
    # pprint.pprint(data)
    entries = []
    for entry in data: push(entries, entry)
    with open(output_csv, 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(entries)
