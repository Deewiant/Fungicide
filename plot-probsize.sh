#!/bin/zsh -G

TIMEOUT=10800

if [[ -z "$1" ]]; then
	echo "Need an argument: benchmark to look at" >&2
	exit 1
fi
bm=$1

n=0

tmpdir=$(mktemp -td)

for interp in data/*; do
	echo -n "$interp..."

	datafile=$tmpdir/$(basename $interp)

	b=0

	len=$(echo "$interp/${bm}-" | wc -c)
	for dir in $interp/${bm}-*; do
		if [[ ! -f $dir/memtime ]]; then continue; fi

		size=$(echo "$dir" | cut -b ${len}-)

		if ! echo $size | grep -q '^[0-9]*$'; then continue; fi

		echo -n " $size..."
		echo $size >> $tmpdir/xtics

		if [[ -f $dir/time ]]; then
			time=$(awk '{s+=$1;if($1>m)m=$1}END{print (s-m)/(NR-1)}' $dir/{mem,}time)
		else
			time=$TIMEOUT
		fi
		echo $time >> $datafile

		(( ++b ))
	done
	if [[ $b -ne 0 ]]; then
		sort -g $datafile > $tmpdir/x
		mv $tmpdir/x $datafile
		(( ++n ))
	fi
	echo
done

echo "$1 solved by $n interpreters."

if [[ $n -eq 0 ]]; then
	exit
fi
echo "Plotting time vs problem size to $bm.eps..."

rm -f $tmpdir/tmp

i=0
xtics='set xtics ('
sort -nu $tmpdir/xtics | while read -r x; do
	xtics="$xtics \"$x\" $i,"
	(( ++i ))
done
xtics=$(echo "$xtics" | sed 's.,$.).')
rm -f $tmpdir/xtics

cmd='plot'
for f in $tmpdir/*; do
	echo "$(wc -l < $f) $(basename $f)"
	cmd="$cmd \"$f\" u 1 t '$(basename $f)', "
done
cmd=$(echo "$cmd" | sed 's., $..')

gnuplot <<ENDPLOT
set term post eps colour
set output "$bm.eps"

set style fill solid border -1

set key reverse Left below

set logscale y

set yrange [:$TIMEOUT]

set format x "%.0f"

set xlabel "Problem size"
set ylabel "Time (s)"

set grid ytics
set xtics nomirror
set ytics nomirror

set style data histograms

set title "$bm"

$xtics

$cmd
ENDPLOT
rm -rf $tmpdir
