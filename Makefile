all:
	( cat 01-preamble.md ; perl walk.pl ; cat 02-footnotes.md ) > README.md

clean:
	rm *~
