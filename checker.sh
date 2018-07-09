#!/bin/sh

cd directory || exit 1

tor_curl() {
    curl -x socks5h://127.0.0.1:9150/ "$@"
    return $?
}

check_onions() {
    for url in `awk '{print $1}' < urls` ; do
        if tor_curl $url >curl.out~ 2>curl.err~ ; then
            echo ":thumbsup:"
        else
            echo ":sos:"
        fi
    done >check-status
    date -u "+%Y-%m-%dT%H:%M:%SZ" >check-date # separate file for less noise
}

for category in * ; do
    echo ":::: $category ::::"
    cd $category || exit 1
    for onion in * ; do
        echo "---- $onion ----"
        cd $onion || exit 1
        check_onions
        cd ..
    done
    cd ..
done
