#!/bin/sh

while read category onion_address proof_url title ; do
    if [ ! -d "directory/$category" ] ; then
        echo oops: bad category $category for $onion_address
        exit 1
    fi

    for existing in `echo directory/*/$onion_address` ; do
        if [ -d "$existing" ] ; then
            echo onion exists at $existing for $title
            continue
        fi
    done

    dir="directory/$category/$onion_address"
    mkdir -p $dir || exit 1

    echo $title >$dir/title
    echo $proof_url >$dir/proof
    echo http://$onion_address/ >$dir/urls # add more by hand, later
done <<EOF
securedrop-for-organisations lzpczap7l3zxu7zv.onion https://www.icij.org/securedrop ICIJ / International Consortium of Investigative Journalists
EOF
