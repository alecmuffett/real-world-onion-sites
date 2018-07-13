all:
	git pull
	#./checker.sh
	( cat 01-preamble.md ; perl walk.pl ; cat 02-footnotes.md ) > README.md
	git add .
	git commit -m "update on `date`"
	touch $(updatefile)


clean:
	rm *~
