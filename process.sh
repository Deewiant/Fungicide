#!/bin/zsh -G
sourceDir=data
targetDir=preprocessed-data

if which prll >&/dev/null; then
	PRLL=true
else
	PRLL=false
fi

tmpd=tmp/process
tmp=$tmpd/tmp

mkdir -p $tmpd
if $PRLL; then mkdir -p $tmpd/{t,m,n}; fi

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
			n=$(($(wc -l < $src/time) + 1))
		elif [[ -f $src/memtime ]]; then
			time=timeout
			n=1
		elif [[ -f $src/time ]]; then
			time=
			myecho "[ERROR :: time but no memtime]"
		else
			time=
		fi
		if [[ -n $time ]]; then
			if $PRLL; then
				echo "$interp $time" > $tmpd/t/$interp
				echo "$interp $n" > $tmpd/n/$interp
			else
				echo "$interp $time" >> $tgt/time
				echo "$interp $n" >> $tgt/runs
			fi
			myecho T
		fi

		if [[ -f $src/mem ]]; then
			mem=$(gunzip -c $src/mem | awk '{if($1>m)m=$1}END{print m/1024}')

			# Hack but unlikely to be wrong anyway...
			if [[ $mem -eq 0 ]]; then
				mem=0.5
			fi
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
		rm -f $tmpd/{t,m,n}/*
		prll doInterp $sourceDir/* 2>/dev/null
		cat $tmpd/t/* > $tgt/time
		cat $tmpd/m/* > $tgt/mem
		cat $tmpd/n/* > $tgt/runs
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
			while [[ $(head -qn1 $tmp | cut -d, -f$j) != $i ]]; do
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
	head -qn1 $targetDir/*/**/$1.csv | sed 's/[^,]*,//;s/,/\n/g' | sort -u | paste -sd, > $targetDir/$1.csv
	cp -a $targetDir/$1.csv $tmpd/h

	for f in $targetDir/*/**/$1.csv; do
		head -qn1 $f > $tmp
		sed 1d $f | while read -r line; do
			i=2
			j=1
			while [[ -n $(cut -d, -f$j $tmpd/h) ]]; do
				while [[ $(cut -d, -f$j $tmpd/h) != $(cut -d, -f$i $tmp) ]]; do
					echo -n ,
					((j++))
				done
				echo -n ,$(echo "$line" | cut -d, -f$i)
				((i++))
				((j++))
			done
			echo
		done
	done | sed 's/^,//' >> $targetDir/$1.csv
	echo -n $2
	((n++))
}
f times T
f mems M
echo

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
