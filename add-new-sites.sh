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
news-and-media https bfnews3u2ox4m4ty.onion proof-in-ssl-cert BuzzFeed News

tech-and-software http lldan5gahapx5k7iafb3s4ikijc4ni7gx5iywdflkba5y2ezyg6sjgyd.onion https://onionshare.org/ OnionShare

tech-and-software http sik5nlgfc5qylnnsr57qrbm64zbdx6t4lreyhpon3ychmxmiem7tioad.onion http://sik5nlgfc5qylnnsr57qrbm64zbdx6t4lreyhpon3ychmxmiem7tioad.onion/ Qubes OS

tech-and-software http dxsj6ifxytlgq33k.onion https://hardenedbsd.org/article/shawn-webb/2017-03-11/hardenedbsd-through-tor-hidden-service Hardened BSD

tech-and-software http 3jkjhrvkdbdkqisnwhdpe4afh2j2g3suhsfcewiemsyk5ecd6gadmxyd.onion https://hardenedbsd.org/article/shawn-webb/2017-03-11/hardenedbsd-through-tor-hidden-service Hardened BSD

EOF
