#!/bin/sh

while read category scheme onion_address proof_url title ; do
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
    echo $scheme://$onion_address/ >$dir/urls # add more by hand, later
done <<EOF
securedrop-for-organisations http lzpczap7l3zxu7zv.onion https://www.icij.org/securedrop ICIJ / International Consortium of Investigative Journalists
tech-and-software https hzwjmjimhr7bdmfv2doll4upibt5ojjmpo3pbp5ctwcg37n3hyk7qzid.onion https://onioncontainers.com/ Ablative Hosting (proof in ssl cert)
civil-society-and-community https xychelseaxqpywe4.onion https://twitter.com/xychelsea/status/989539441978040321 Chelsea Manning for US Senate
EOF
