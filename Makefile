DB=fetch.sqlite3

all:
	-echo "make what?"

run:
	./wrapper.sh

clean:
	-rm *~
	-rm log*.txt

db:
	sqlite3 $(DB)

db-nuke: clean
	-rm $(DB) $(DB)-*
