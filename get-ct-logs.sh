#!/bin/sh

log=ct-log.txt

curl "https://crt.sh/?q=%25.onion" |
    perl -nle 'next unless m!TD.*onion!; s!<.*?>! !g; s!(^\s+|\s+$)!!g; print' |
    sort -u >$log

exit 0
