#!/bin/sh

cd directory || exit 1

tor_curl() {
    curl -x socks5h://127.0.0.1:9150/ "$@"
    return $?
}

check_onion() {
    is_up=true

    for prefix in check-status check-date ; do
        test -f $prefix-3 && mv $prefix-3 $prefix-4
        test -f $prefix-2 && mv $prefix-2 $prefix-3
        test -f $prefix-1 && mv $prefix-1 $prefix-2
        test -f $prefix && mv $prefix $prefix-1
    done

    for url in `awk '{print $1}' < urls` ; do
        if tor_curl $url >curl.out~ 2>curl.err~ ; then
            echo ":thumbsup:"
        else
            is_up=false # one bad apple
            echo ":sos:"
        fi
    done >check-status

    date -u "+%Y-%m-%dT%H:%M:%SZ" >check-date
}

for category in * ; do
    echo ":::: $category ::::"
    cd $category || exit 1
    for onion in * ; do
        echo "---- $onion ----"
        cd $onion || exit 1
        check_onion
        cd ..
    done
    cd ..
done

date -u "+%Y-%m-%dT%H:%M:%SZ" >.check-date
