#!/bin/sh

src=README.md
dst=${src}~~

for output in out/* ; do
    test ! -s $output || continue
    onion=`basename $output`
    echo annotating: $onion
    perl -pe "s!\$! :sos:! if (m!$onion!);" <$src >$dst
    mv $dst $src
done
