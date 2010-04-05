#!/bin/zsh

TIMEINTERVAL1=600 # Intervals of y tics/lines in graph
TIMEINTERVAL2=60
TIMEOUT=10800
MINALLOWED=1      # Don't plot points below this

if [[ $# -lt 2 || $# -gt 5 ]]; then
	echo "Usage: $0 <output file> <data file> [xmin [xmax [ymax]]]" >&2
	exit 1
fi
out=$1
f=$2
xmin=$3
xmax=$4
ymax=$5

if [[ ! -f $f ]]; then
	echo "File not found: '$f'" >&2
	exit 1
fi

if [[ -n $xmin ]]; then
	minmax=$(<<EOF
set xrange [$xmin:$xmax]
set arrow from $xmin,$TIMEOUT to $xmax,$TIMEOUT nohead linetype rgb "red" linewidth .5
EOF)
else
	minmax=
fi

if [[ -n $ymax ]]; then
	timelimit="set yrange [0:$ymax]"
else
	timelimit=
fi

tmpdir=tmp/cactus
mkdir -p $tmpdir

# Doesn't handle quoted strings in the CSV but oh well
headers=$(head -n1 $f)
cols=$(echo "$headers" | awk -F, '{print NF}')

dataplot=
first=true
for c in $(seq 1 $cols); do
	# Grab the wanted column and sort it
	awk -F, "NR==1 {print \$$c} NR > 1 {print \$$c | \"sort -g\"}" $f | \
		\
		# Forget about timeouts
		fgrep -v $TIMEOUT | \
		\
		# Add X-coordinate, skip too small ones
		awk -F, "NR==1 {print} NR>1 {i++} NR>1 && \$1 >= $MINALLOWED {OFS=\",\"; print i,\$1}" |
		\
		> $tmpdir/$c

	# If all timed out, just skip the file
	if [[ -z $(sed 1d $tmpdir/$c) ]]; then
		continue
	fi

	if $first; then
		first=false
	else
		dataplot="$dataplot,"
	fi
	dataplot="$dataplot \"$tmpdir/$c\" using 1:2 title 1"
done

gnuplot <<EOF
set terminal postscript colour solid "Helvetica,10pt"
set output "$out"
set style data linespoints
set datafile separator ","

# set title "$f"
set key left Left reverse spacing 1.5 at graph 0.01, graph 0.99

set xlabel "Benchmarks completed"
set ylabel "Time (s)"

set xtics 0,5
set ytics 0,$TIMEINTERVAL1
set mytics $((TIMEINTERVAL1/TIMEINTERVAL2))

$timelimit

$minmax

plot $dataplot
EOF
sed -i 's/^LT5/LT8/' $out