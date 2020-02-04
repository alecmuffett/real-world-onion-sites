#!/bin/sh

log=ct-log.txt
tf=/tmp/ctget$$.txt

curl "https://crt.sh/?q=%25.onion" |
    perl -nle 'next unless m!TD.*\.onion\b!; s!\s+!\n!go; s!</?TD>!\n!goi; s!<BR>!\n!goi; print' |
    egrep '\.onion$' |
    sort -u |
    rev |
    sort |
    rev >$tf

test -s $tf && cp $tf $log
rm $tf

exit 0
