#!/bin/sh

log=ct-log.md
tf=/tmp/ctget$$.txt
sanity=facebookwkhpilnemxj7asaniu7vnjjbiltxjqhye3mhbshg7kx5tfyd

(
    echo "# Onion Certificate Transparency Log"
    echo "## This file is auto-generated (without editorial assistance) from CA certificate issuance logs"
    ./onion-ctlog.py
) > $tf

#curl "https://crt.sh/?q=\.onion" |
#    perl -nle 'next unless m!TD.*\.onion\b!; s!\s+!\n!go; s!</?TD>!\n!goi; s!<BR>!\n!goi; print' |
#    egrep '[2-7a-z]{56}\.onion$' |
#    sort -u |
#    awk -F. '{print $(NF-1), $0}' |
#    sort |
#    awk 'BEGIN {print "# Onion Certificate Transparency Log";print "## This file is auto-generated (without editorial assistance) from CA certificate issuance logs"} $2~/^\*/{print "* *wildcard* `" $2 "`"; next} {url = "https://" $2; printf("* [`%s`](%s)\n",url,url)}' >$tf

grep $sanity $tf &&
    cp $tf $log &&
    rm $tf

exit 0
