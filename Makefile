DB=fetch.sqlite3

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
	-rm log*.txt

db:
	sqlite3 $(DB)

db-nuke: clean
	-rm $(DB) $(DB)-* master.csv
