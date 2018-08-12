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
tech-and-software http kkkkkkkkkk63ava6.onion https://www.qubes-os.org/news/2018/01/23/qubes-whonix-next-gen-tor-onion-services/ Whonix

EOF
