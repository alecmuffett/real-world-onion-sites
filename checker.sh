#!/bin/sh

doc=https://raw.githubusercontent.com/alecmuffett/onion-sites-that-dont-suck/master/README.md
tf=onions~txt~

for dir in out err ; do
    test -d $dir || mkdir $dir || exit 1
done

if [ ! -s $tf ] ; then
    tor-curl $doc |
        perl -pe 's/\s+/\n/g' |
        perl -pe 's!^(https?://.*?/).+$!$1!' |
        sort -u |
        egrep '^https?://.*\.onion/' > $tf
fi

for url in `randsort < $tf` ; do
    host=`basename $url`
    if [ ! -s out/$host ] ; then
        echo polling: $host `date`
        tor-curl $url >out/$host 2>err/$host
    else
        echo skipping: $host
    fi
done
