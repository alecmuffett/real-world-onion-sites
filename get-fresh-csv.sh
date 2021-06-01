#!/bin/sh -x
# yes, this is intentionally a public URL
url='https://docs.google.com/spreadsheets/d/e/2PACX-1vRjEEqZ2bGYQcvTvWqJfNvw_NCTrcIM9C2GzriqGyEfz_8C9ZAj2c9gaR6ew6u4X-qRsYxgeD_zZMxD/pub?gid=0&single=true&output=csv'
tmp="/tmp/onion-tmp-$$.csv"
csv="master.csv" # must match caller-script

curl -Lv "$url" > $tmp || exit 1

if [ -s $tmp ] ; then
    cmp $tmp $csv || cp $tmp $csv
fi
