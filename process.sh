#!/bin/zsh -G
sourceDir=data
targetDir=preprocessed-data
TIMEOUT=10800

if which prll >&/dev/null; then
	PRLL=true
else
	PRLL=false
fi

tmpd=tmp/process
tmp=$tmpd/tmp

mkdir -p $tmpd
if $PRLL; then mkdir -p $tmpd/{t,m}; fi

for interp in $sourceDir/*; do
	for benchmark in $interp/*; do
		basename $benchmark >> $tmp
	done
done

startTime=$(date +%s.%N)
n=0

rm -rf $targetDir

prevBM=
for benchmark in $(sort -u $tmp); do
	bm=$(basename $benchmark | sed 's/-[0-9]\+$//')
	param=$(basename $benchmark | sed 's/.*-\([0-9]\+$\)/\1/')

	tgt=$targetDir/$bm/$param
	mkdir -p $tgt

	if [[ $bm != $prevBM ]]; then
		echo "$bm..."
		prevBM=$bm
	fi

	echo "\t$param..."

	doInterp() {
		interp=$(basename $1)
		s=
		if $PRLL; then myecho() { s="$s$1"; }
		else myecho() { echo -n "$1"; }
		fi
		myecho "\t\t$interp... "

		src=$1/$benchmark

		if [[ -f $src/time && -f $src/memtime ]]; then
			time=$(awk '{s+=$1;if($1>m)m=$1}END{print (s-m)/(NR-1)}' $src/{mem,}time)
		elif [[ -f $src/memtime ]]; then
			time=$TIMEOUT
		elif [[ -f $src/time ]]; then
			time=
			myecho "[ERROR :: time but no memtime]"
		else
			time=
		fi
		if [[ -n $time ]]; then
			if $PRLL; then
				echo "$interp $time" > $tmpd/t/$interp
			else
				echo "$interp $time" >> $tgt/time
			fi
			myecho T
		fi

		if [[ -f $src/mem ]]; then
			mem=$(gunzip -c $src/mem | awk '{if($1>m)m=$1}END{print m/1024}')
		else
			mem=
		fi
		if [[ -n $mem ]]; then
			if $PRLL; then
				echo "$interp $mem" > $tmpd/m/$interp
			else
				echo "$interp $mem" >> $tgt/mem
			fi
			myecho M
		fi
		echo $s
	}

	if $PRLL; then
		rm -f $tmpd/{t,m}/*
		prll doInterp $sourceDir/* 2>/dev/null
		cat $tmpd/t/* > $tgt/time
		cat $tmpd/m/* > $tgt/mem
	else
		for interp in $sourceDir/*; do
			doInterp $interp
		done
	fi

	echo -n "\tSorting... "
	sort -gsk2 $tgt/time > $tmp; mv $tmp $tgt/time; echo -n T; ((n++))
	sort -gsk2 $tgt/mem  > $tmp; mv $tmp $tgt/mem;  echo -n M; ((n++))
	echo
done

echo -n "Summarizing... "
for bm in $targetDir/*; do
	rm -f $tmpd/{times,mems}

	for param in $bm/*; do
		if [[ -d $param ]]; then
			param=$(basename $param)
			sed "s/^/$param /" $bm/$param/time >> $tmpd/times
			sed "s/^/$param /" $bm/$param/mem >> $tmpd/mems
		fi
	done

	f() {
		echo -n foo > $tmp
		sort -k2,2 $tmpd/${1}s -u | cut '-d ' -f2 | xargs -n1 printf ",%s" >> $tmp
		pp=
		sort -gk1,1 -k2,2 $tmpd/${1}s | while read -r p i t; do
			if [[ $p != $pp ]]; then
				echo -n "\n$p" >> $tmp
				pp=$p
				j=1
			fi
			((j++))
			while [[ $(head -n1 $tmp | cut -d, -f$j) != $i ]]; do
				echo -n , >> $tmp
				((j++))
			done
			echo -n ",$t" >> $tmp
		done
		echo >> $tmp
		mv $tmp $bm/${1}s.csv
		((n++))
		echo -n $2
	}
	f time T
	f mem M
done
echo

echo -n "Summarizing... "
f() {
	first=true
	for f in $targetDir/*/**/$1.csv; do
		if $first; then
			<$f
			first=false
		else
			sed 1d $f
		fi
	done | sed 's/[^,]*,//' > $targetDir/$1.csv
	echo -n $2
	((n++))
}
f times T
f mems M
echo

rm -rf $tmpd

echo -n "Created $n files in "

endTime=$(date +%s.%N)
diff=$((endTime - startTime))

part() {
	if [[ $diff -ge $1 ]]; then
		n=$(echo $((diff / $1)) | cut -d. -f1)
		echo -n "$n $2 "
		while [[ $diff -ge $1 ]]; do
			diff=$((diff - $1))
		done
	fi
}
part 3600 hours
part   60 minutes

echo "$diff seconds."
