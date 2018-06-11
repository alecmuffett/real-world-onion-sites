#!/bin/sh

src=README.md
dst=${src}~~

for output in out/* ; do
    test ! -s $output || continue
    onion=`basename $output`
    echo annotating: $onion
    perl -pi "s/$/ :sos:/ if /$output/" <$src >$dst
    mv $dst $src
done
