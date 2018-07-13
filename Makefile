README.md:
	( cat 01-preamble.md ; perl walk.pl ; cat 02-footnotes.md ) > README.md

update:
	git pull
	./checker.sh
	make README.md
	git add .

clean:
	rm *~
