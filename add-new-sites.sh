#!/bin/sh

while read category scheme onion_address proof_url title ; do
    test x$category = x && continue

    if [ ! -d "directory/$category" ] ; then
        echo oops: bad category $category for $onion_address
        exit 1
    fi

    for existing in `echo directory/*/$onion_address` ; do
        if [ -d "$existing" ] ; then
            echo onion exists at $existing for $title
            continue 2 # skip 2 levels to the next onion
        fi
    done

    dir="directory/$category/$onion_address"
    echo "making $dir"
    mkdir -p $dir || exit 1

    echo $title >$dir/title
    echo $proof_url >$dir/proof
    echo $scheme://$onion_address/ >$dir/urls # add more by hand, later
done <<EOF
news-and-media https www.bbcnewsv2vjtpsuy.onion https://www.bbc.co.uk/news/technology-50150981 BBC News
web-and-internet http archivecaslytosk.onion https://archive.is/ Archive Today (archive.is)
EOF
