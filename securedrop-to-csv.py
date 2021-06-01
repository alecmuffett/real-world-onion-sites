#!/usr/bin/env python3

import csv
import pprint
import json
import requests

output_csv = 'securedrop-api.csv'
sd_url = 'https://securedrop.org/api/v1/directory/'
fieldnames = "legacy flaky category site_name onion_name onion_addr onion_url proof_url comment".split()

def xx(thing, key): return thing.get(key, '')

def push(stack, entry):
    if entry['latest_scan']['forces_https']:
        method = 'https'
    else:
        method = 'http'
    result = dict()
    result['legacy'] = 'FALSE'
    result['flaky'] = ''
    result['category'] = 'securedrop for organisations'
    result['site_name'] = xx(entry, 'title')
    result['onion_url'] = '{0}://{1}'.format(method, xx(entry, 'onion_address'))
    result['onion_addr'] = 'TO BE COMPUTED BY SHEET'
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
