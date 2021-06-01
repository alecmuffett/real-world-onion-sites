#!/bin/sh
# hello! yes, this is a public link to a google sheet, to fetch as csv; and yes, i do know.
url='google broke this function'
now=`date "+%Y%m%d%H%M%S"`
log="log-$now.txt"
csv="master.csv"
exe="./rwos-db.py"

exec </dev/null 2>$log 1>&2

case "x$1" in
    x-n) dofetch=false ;;
    *) dofetch=true ;;
esac

set -x

# date
# todo: update the CSV?

date
if $dofetch ; then
    $exe fetch || exit 1
fi

date
(
    cat 01-preamble.md
    echo ""
    $exe print || exit 1
    echo ""
    cat 02-footnotes.md
    echo ""
) > README.md

date
$exe trash

date
exit 0
