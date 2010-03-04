#!/bin/bash
if [[ ! -d interpreters ]]; then
	echo "Wrong dir?" >&2
	exit 1
fi
for p in $(ps ax | grep onepid_mem.py | grep -v grep | awk '{print $1}'); do
	sudo kill $p
	echo "Killed onepid_mem.py $p"
done
for f in interpreters/*; do
	for p in $(ps ax | grep $f | grep -v grep | awk '{print $1}'); do
		kill $p
		echo "Killed $f $p"
	done
done
rm -rfv tmp
