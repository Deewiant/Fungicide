#!/bin/zsh

out=plotstables
in=preprocessed-data

if which prll >&/dev/null; then
	PRLL=true
	rm -rf tmp/make-all-analyses
	mkdir tmp/make-all-analyses
else
	PRLL=false
fi

startTime=$(date +%s.%N)
n=0

rm -rf $out
mkdir $out

echo -n CT; analysis/cactus-time.sh $out/cactus-time.svg $in/times.csv 40 75; echo -n ' '; ((++n))
echo -n CTd; analysis/cactus-time.sh $out/cactus-time-detailed.svg $in/times.csv 60 75 1800; echo -n ' '; ((++n))
echo -n CM; analysis/cactus-mem.sh $out/cactus-mem.svg $in/mems.csv 40 75; echo -n ' '; ((++n))
echo -n TS; analysis/table-summary.sh $in/{time,mem}s.csv > $out/table-summary.html; echo; ((++n))

for bm in $in/*; do
	if [[ ! -d $bm ]]; then continue; fi

	echo -n "$(basename $bm)... "

	od=$out/$(basename $bm)
	mkdir -p $od
	echo -n LT; analysis/line-time-vs-size.sh $od/line-time.svg $bm 12000; echo -n ' '; ((++n))
	echo -n LM; analysis/line-mem-vs-size.sh $od/line-mem.svg $bm; echo -n ' '; ((++n))
	echo -n TB; analysis/table-benchmark.sh $bm > $od/table-summary.html; echo; ((++n))

	doParam() {
		if [[ ! -d $1 ]]; then return; fi
		p=$1

		s=
		if $PRLL; then
			myecho() { s="$s$1"; }
			tmpd=$(mktemp -dp tmp/make-all-analyses/)
		else
			myecho() { echo -n "$1"; }
			tmpd=
		fi

		myecho "\t$(basename $p)... "

		od=$od/$(basename $p)
		mkdir -p $od
		myecho LMT; analysis/line-mem-vs-time.sh $od/line-memtime.svg $(basename $bm)-$(basename $p) $tmpd/ >/dev/null; myecho ' '
		myecho TP; analysis/table-specific.sh $p $tmpd/ > $od/table.html; myecho ' '
		echo $s
		rm -rf $tmpd
	}

	if $PRLL; then
		prll doParam $bm/* |& grep -v '^PRLL'
		((n+=2))
	else
		for p in $bm/*; do
			doParam $p
		done
	fi
done

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
