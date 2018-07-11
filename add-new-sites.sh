#!/bin/sh

while read category scheme onion_address proof_url title ; do
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
securedrop-for-organisations http lzpczap7l3zxu7zv.onion https://www.icij.org/securedrop ICIJ / International Consortium of Investigative Journalists
tech-and-software https hzwjmjimhr7bdmfv2doll4upibt5ojjmpo3pbp5ctwcg37n3hyk7qzid.onion proof-in-ssl-cert Ablative Hosting
civil-society-and-community https xychelseaxqpywe4.onion https://twitter.com/xychelsea/status/989539441978040321 Chelsea Manning for US Senate
news-and-media https p53lf57qovyuvwsc6xnrppyply3vtqm7l6pcobkmyqsiofyeznfu5uqd.onion proof-in-ssl-cert ProPublica
securedrop-for-organisations https y27vf7g2ce5g3fnl.onion proof-in-ssl-cert Aftonbladet
EOF
