#!/bin/sh
SOCKS_PROXY='socks5h://127.0.0.1:9050/'
USER_AGENT='Mozilla/5.0 (Windows NT 6.1; rv:60.0) Gecko/20100101 Firefox/60.0'
for url in "$@" ; do
    echo ":::: $url ::::"
    curl --head --user-agent "$USER_AGENT" --proxy "$SOCKS_PROXY" "$url" || exit $?
done
exit 0
