#!/bin/bash
#converts tabs to spaces

#how many spaces do you want a tab to be
tabsize=8

#you shouldn't need to change anything below this

tab=
for i in $(seq $((tabsize-1))); do
	tab="$tab "
done


test -d converted && rm -rf converted
mkdir converted || { 
	echo "could not create 'converted' dir">&2
	exit 1
}


for f in *erl; do 
	sed "s/\t/$tab/g" < $f > converted/$f 
done

cp Makefile slave master debug.sh runerl.sh converted
