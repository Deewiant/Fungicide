#!/bin/zsh

if [[ -z "$1" ]]; then
	echo "Need an argument: benchmark to look at" >&2
	exit 1
fi
bm=$1

n=0

tmpdir=$(mktemp -td)

for interp in data/*; do
	dir=$interp/$bm
	if [[ ! -f $dir/memtime ]]; then continue; fi

	echo -n "$interp..."

	zcat $dir/mem | fgrep -vw 0 > $tmpdir/tmp

	mems=$(wc -l < $tmpdir/tmp)
	memInterval=$(( $(cat $dir/memtime) / $mems ))

	datafile=$tmpdir/$(basename $interp)

	awk "{++n; print $memInterval*n, \$1 / 1024}" $tmpdir/tmp >> $datafile

	(( ++n ))
	echo
done

echo "$1 solved by $n interpreters."

if [[ $n -eq 0 ]]; then
	exit
fi
echo "Plotting mem vs time to $bm.eps..."

rm -f $tmpdir/tmp

cmd='plot '
for f in $tmpdir/*; do
	echo "$(wc -l < $f) $(basename $f)"
	cmd="$cmd \"$f\" u 1:2 t '$(basename $f)', "
done
cmd=$(echo "$cmd" | sed 's., $..')

gnuplot <<ENDPLOT
set term post eps colour
set output "$bm.eps"

set key reverse Left below

set logscale x
set logscale y 2

set xlabel "Time (s)"
set ylabel "Mem use (Mio)"

set yrange [1:]

set style data lines

set title "$bm"

$cmd
ENDPLOT
rm -rf $tmpdir
echo Done.
