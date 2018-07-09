all:
	( cat 01-preamble.md ; cat 02-footnotes.md ) > README.md

clean:
	rm *~
