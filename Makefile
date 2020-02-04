DB=fetch.sqlite3
LOGDIR=old-logs

all:
	-echo "make what?"

run:
	git pull
	./wrapper.sh
	./get-ct-log.sh
	git add .
	git commit -m "auto-update on `date`"
	git push

clean:
	-rm *~
	test -d $(LOGDIR) || mkdir $(LOGDIR)
	mv log*.txt $(LOGDIR)
	ls -lh

db:
	sqlite3 $(DB)

db-nuke: clean
	-rm $(DB) $(DB)-* master.csv
