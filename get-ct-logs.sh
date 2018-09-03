#!/bin/sh

log=ct-log.txt
tf=/tmp/ctget$$.txt

curl "https://crt.sh/?q=%25.onion" |
    perl -nle 'next unless m!TD.*onion!; s!<.*?>! !g; s!(^\s+|\s+$)!!g; print' |
    sort -u >$tf

test -s $tf && cp $tf $log
rm $tf

exit 0
