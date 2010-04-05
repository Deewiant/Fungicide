#!/bin/zsh

MAXMEM=8192
TIMEOUT=10800

if [[ $# -ne 2 ]]; then
	echo "Usage: $0 <output file> <name of benchmark+param>" >&2
	exit 1
fi
out=$1
bm=$2
ymax=10240

n=0

tmpdir=tmp/memplot
mkdir -p $tmpdir

for interp in data/*; do
	dir=$interp/$bm
	if [[ ! -f $dir/memtime ]]; then continue; fi

	echo -n "$interp..."

	gunzip -c $dir/mem | grep -v '^0$' > $tmpdir/tmp

	mems=$(wc -l < $tmpdir/tmp)
	memInterval=$(( $(cat $dir/memtime) / $mems ))

	awk "{++n; print $memInterval*n, \$1 / 1024}" $tmpdir/tmp > $tmpdir/$(basename $interp)
	(( ++n ))
	echo
done

echo "$1 solved by $n interpreters."
if [[ $n -eq 0 ]]; then
	exit
fi
rm -f $tmpdir/tmp

cmd=
for f in $tmpdir/*; do
	echo "$(wc -l < $f) $(basename $f)"
	cmd="$cmd \"$f\" u 1:2 t '$(basename $f)',"
done
cmd=$(echo "$cmd" | sed 's.,$..')

gnuplot <<ENDPLOT
set term post eps colour "Helvetica,12pt"
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

set xrange [0.001:]

set style data lines

set title "$bm"

set arrow from 0.001,$MAXMEM to graph 1,0.977 nohead linetype rgb "red"
set y2tics add ($MAXMEM)

plot $cmd
ENDPLOT
sed -i 's/^LT5/LT8/' $out
