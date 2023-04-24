#!/bin/sh
now=`date "+%Y%m%d%H%M%S"`
log="log-$now.txt"
csv="master.csv"
exe="./rwos-db.py"

#exec </dev/null 2>$log 1>&2

case "x$1" in
    x-n) dofetch=false ;;
    *) dofetch=true ;;
esac

set -x

if $dofetch ; then
    date
    ./get-fresh-csv.sh || exit 1
    date
    ./get-securedrop-csv.py || exit 1
    date
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
