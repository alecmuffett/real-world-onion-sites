#!/bin/sh

log=ct-log.txt
tf=/tmp/ctget$$.txt

curl "https://crt.sh/?q=\.onion" |
    perl -nle 'next unless m!TD.*\.onion\b!; s!\s+!\n!go; s!</?TD>!\n!goi; s!<BR>!\n!goi; print' |
    egrep '[2-7a-z]{56}\.onion$' |
    sort -u |
    awk -F. '{print $(NF-1), $0}' |
    sort |
    awk '{print $2}' >$tf

test -s $tf && cp $tf $log
rm $tf

exit 0
