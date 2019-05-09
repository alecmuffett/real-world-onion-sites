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
government http ciadotgov4sjwlzihbbgxnqg3xiyrg7so2r2o3lt5wz5ypk4sxyjstad.onion https://www.cia.gov/news-information/featured-story-archive/2019-featured-story-archive/latest-layer-an-onion-site.html US Central Intelligence Agency
EOF

#web-and-internet ???? freenodeok2gncmy.onion https://freenode.net/kb/answer/chat Freenode
#web-and-internet ???? ajnvpgl6prmkb7yktvue6im5wiedlz2w32uhcwaamdiecdrfpwwgnlqd.onion https://freenode.net/kb/answer/chat Freenode
