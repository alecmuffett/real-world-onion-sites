#!/bin/sh
db=fetch.sqlite3
for onion in "$@" ; do
    sqlite3 -readonly $db "select * from fetches where url like '%${onion}%' order by ctime asc;"
done
