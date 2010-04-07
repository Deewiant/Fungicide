#!/bin/zsh -G

MAXMEM=8192
TIMEOUT=10800
TIMEOUT_XMAX=15000 # otherwise automatic

if [[ $# -lt 2 ]]; then
	echo "Usage: $0 <output file> <name of benchmark+param> [tmp dir prefix]" >&2
	exit 1
fi
out=$1
bm=$2
ymax=10240

n=0
gotTimeout=false

tmpdir=${3}tmp/memplot
mkdir -p $tmpdir

rm -f $tmpdir/*
for interp in data/*; do
	dir=$interp/$bm
	if [[ ! -f $dir/memtime ]]; then continue; fi

	echo -n "$interp..."

	gunzip -c $dir/mem | grep -v '^0$' > $tmpdir/tmp

	mems=$(wc -l < $tmpdir/tmp)

	echo -n "$mems samples"

	if [[ $mems -ne 0 ]]; then
		mt=$(cut '-d ' -f2 $dir/memtime)
		memInterval=$(($mt/$mems))

		if [[ $mt -ge $TIMEOUT ]]; then
			gotTimeout=true
		fi

		echo -n ", total time $mt: interval $memInterval"

		awk "{++n; print $memInterval*n, \$1 / 1024}" $tmpdir/tmp > $tmpdir/$(basename $interp)
		(( ++n ))
	fi
	echo
done

echo "$bm solved by $n interpreters."
if [[ $n -eq 0 ]]; then
	exit
fi
rm -f $tmpdir/tmp

cmd=
for f in $tmpdir/*; do
	cmd="$cmd \"$f\" u 1:2 t '$(basename $f)',"
done
cmd=$(echo "$cmd" | sed 's.,$..')

if $gotTimeout; then
	xmax=$TIMEOUT_XMAX
	timeoutarrow="set arrow from $TIMEOUT,0.5 to $TIMEOUT,$MAXMEM nohead lt 0 lw 3"
else
	xmax=
	timeoutarrow=
fi

gnuplot <<ENDPLOT
set terminal svg dashed font "Helvetica"
set output "$out"

set key left Left reverse at graph 0.01, graph 0.97

set logscale x
set logscale y 2

set logscale y2 2
set ytics format "" # preferable to unset, since y and y2 show discrepancies without ymax
set y2tics mirror
set yrange [0.5:$ymax]
set y2range [0.5:$ymax]
set grid y2tics

set xlabel "Time (s)"
set y2label "Memory use (Mio)"

set xrange [0.001:$xmax]

set style data lines

set title "$bm"

set arrow from 0.001,$MAXMEM to graph 1,0.977 nohead lt 0 lw 3
$timeoutarrow

set y2tics add ($MAXMEM)

plot $cmd
ENDPLOT
#sed -i 's/^LT5/LT8/' $out
