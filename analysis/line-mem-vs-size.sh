#!/bin/zsh -G

MAXMEM=8192

if [[ $# -lt 2 || $# -gt 3 ]]; then
	echo "Usage: $0 <output file> <preprocessed benchmark dir> [ymax]" >&2
	exit 1
fi
out=$1
bm=$2
ymax=$3

[[ -n $ymax ]] || ymax=10240

cmd=
for c in $(seq 2 $(head -qn1 $bm/mems.csv | awk -F, '{print NF}')); do
	cmd="$cmd \"$bm/mems.csv\" u $c:xticlabels(1) t '$(head -qn1 $bm/mems.csv | awk -F, "{print \$$c}")',"
done
cmd=$(echo "$cmd" | sed 's.,$..')

lines=$(wc -l < $bm/mems.csv)
xmax=$(echo $(($lines-0.5)))

gnuplot <<ENDPLOT
set terminal svg solid font "Helvetica"
set output "$out"
set datafile separator ","

set key left Left reverse at graph 0.01, graph 0.97

set logscale y 2
set ytics format "" # preferable to unset, since y and y2 show discrepancies without ymax
set logscale y2 2
set y2tics mirror
set yrange [1:$ymax]
set y2range [1:$ymax]
set grid y2tics

set xtics nomirror

set xlabel "Problem size"
set y2label "Memory use (Mio)"

set style data linespoints

set title "$(basename $bm)"

set xrange [0.5:$xmax]

set arrow from 0.5,$MAXMEM to $xmax,$MAXMEM nohead linetype rgb "red"

set y2tics add ($MAXMEM)

plot $cmd
ENDPLOT
sed -i 's/^LT5/LT8/' $out
