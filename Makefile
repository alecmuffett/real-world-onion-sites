all:
	git pull
	./checker.sh
	git pull
	( cat 01-preamble.md ; perl walk.pl ; cat 02-footnotes.md ) > README.md
	./get-ct-logs.sh
	git add .
	git commit -m "auto-update on `date`"

clean:
	rm *~

wat:
	git diff HEAD^
