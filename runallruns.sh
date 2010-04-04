#!/bin/zsh

rn=$(wc -l < runs.dat)
in=$(wc -l < interpreters.dat)
for i in $(seq 1 $in); do
	int=$(sed -n ${i}p interpreters.dat | awk '{print $1}')
	if echo "$int" | grep -q "^#" || echo "$int" | egrep -q "^\s*$"; then
		continue
	fi
	echo "$int:"
	for r in $(seq 1 $rn); do
		echo " $(sed -n ${r}p runs.dat | awk '{print $1}'):"
		./runonerun.sh $i $r
	done
done
