#!/bin/zsh -G

TIMEOUT=10800

if [[ $# -lt 2 || $# -gt 3 ]]; then
	echo "Usage: $0 <output file> <preprocessed benchmark dir> [ymax]" >&2
	exit 1
fi
out=$1
bm=$2
ymax=$3

mkdir -p tmp
tmp=tmp/tmp
sed s/timeout//g $bm/times.csv > $tmp

cmd=
for c in $(seq 2 $(head -qn1 $tmp | awk -F, '{print NF}')); do
	cmd="$cmd \"$tmp\" u $c:xticlabels(1) t '$(head -qn1 $tmp | awk -F, "{print \$$c}")',"
done
cmd=$(echo "$cmd" | sed 's.,$..')

lines=$(wc -l < $tmp)
xmax=$(echo $(($lines-0.5)))

gnuplot <<ENDPLOT
set terminal svg solid font "Helvetica"
set output "$out"
set datafile separator ","

set key left Left reverse at graph 0.01, graph 0.99

set logscale y
set ytics format "" # preferable to unset, since y and y2 show discrepancies without ymax
set logscale y2
set y2tics mirror
set yrange [0.001:$ymax]
set y2range [0.001:$ymax]
set grid y2tics

set xtics nomirror

set xlabel "Problem size"
set y2label "Time (s)"

set style data linespoints

set title "$(basename $bm)"

set xrange [0.5:$xmax]

set arrow from 0.5,$TIMEOUT to $xmax,$TIMEOUT nohead linetype rgb "red"

plot $cmd
ENDPLOT
sed -i 's/^LT5/LT8/' $out
