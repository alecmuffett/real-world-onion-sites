#!/bin/sh

while read category onion_address proof_url title ; do
    if [ ! -d "directory/$category" ] ; then
        echo oops: bad category $category for $onion_address
        exit 1
    fi
    existing=`echo directory/*/$onion_address` # bueller?
    test -d "$existing" && continue
    where="directory/$category/$onion_address"
    mkdir -p $where || exit 1
    echo $title > $where/title
    echo http://$onion_address/ > $where/urls
    echo $proof_url > $where/proof
done <<EOF
securedrop-for-organisations lzpczap7l3zxu7zv.onion https://www.icij.org/securedrop ICIJ / International Consortium of Investigative Journalists
EOF
