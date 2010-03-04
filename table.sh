#!/bin/zsh

TIMEOUT=10800

if [[ -z "$1" || -z "$2" ]]; then
	echo "Usage: $0 <interp> <interp>" >&2
	exit 1
fi

set -G
bms=$(echo data/$1/* data/$2/* | xargs -n1 basename | sed s/98-/—/ | sort -t— -k2 -g | sort -t— -k1,1 -s | uniq | sed s/—/98-/)

cat <<EOF
<html>
<head>
<title>$0-generated comparison of $1 vs $2</title>
<style>
.g{background-color:springgreen}
.b{background-color:tomato}
table{border-collapse:collapse}
td{border:2px solid black;padding:3px}
</style>
</head>
<body>
<p>Time is in seconds, memory in mebioctets.</p>
<table>
<thead><tr>
<td>Benchmark</td><td>Mean time $1</td><td>Mean time $2</td><td>Difference</td><td>Improvement</td><td>Max memory $1</td><td>Max memory $2</td><td>Difference</td><td>Improvement</td>
</tr></thead><tbody>
EOF

function class2 {
	if [[ -z "$1" || -z "$2" || $1 -eq $2 ]]; then
		echo n
	elif [[ $1 -lt $2 ]]; then
		echo b
	else
		echo g
	fi
}

for bm in $(echo $bms); do
	echo -n "$bm...">&2
	if [[ -f data/$1/$bm/time ]]; then
		mean1=$(awk '{s+=$1;if($1>m)m=$1}END{print (s-m)/(NR-1)}' data/$1/$bm/{mem,}time)
	elif [[ -f data/$1/$bm/memtime ]]; then
		mean1=$TIMEOUT
	else
		mean1=
	fi
	if [[ -f data/$2/$bm/time ]]; then
		mean2=$(awk '{s+=$1;if($1>m)m=$1}END{print (s-m)/(NR-1)}' data/$2/$bm/{mem,}time)
	elif [[ -f data/$2/$bm/memtime ]]; then
		mean2=$TIMEOUT
	else
		mean2=
	fi
	if [[ -z "$mean1$mean2" ]]; then
		echo >&2 " skipped"
		continue
	fi
	echo "<tr><td>$bm</td>"

	echo "<td>$(printf "%.4f" $mean1)</td>"
	echo "<td>$(printf "%.4f" $mean2)</td>"
	c=$(class2 "$mean1" "$mean2")
	if [[ $c = n ]]; then
		echo "<td></td>"
		echo -n "<td>"
	else
		diff=$((mean2-mean1))
		impr=$(((1.0*$diff/mean1)*100))
		echo "<td class=$c>$(printf "%+.3f" $diff)</td>"
		echo -n "<td class=$c>$(printf "%+.2f%%" $impr)"

		diffs="$diffs$diff\n"
		imprs="$imprs$impr\n"
	fi
	echo "</td>"

	if [[ -f data/$1/$bm/mem ]]; then
		mem1=$(zcat data/$1/$bm/mem | awk '{if($1>m)m=$1}END{print m/1024}')
	else
		mem1=
	fi
	if [[ -f data/$2/$bm/mem ]]; then
		mem2=$(zcat data/$2/$bm/mem | awk '{if($1>m)m=$1}END{print m/1024}')
	else
		mem2=
	fi

	echo "<td>$(printf "%.2f" $mem1)</td>"
	echo "<td>$(printf "%.2f" $mem2)</td>"
	c=$(class2 "$mem1" "$mem2")
	if [[ $c = n || $mean1 -eq $TIMEOUT || $mean2 -eq $TIMEOUT ]]; then
		echo "<td></td>"
		echo -n "<td>"
	else
		diff=$((mem2-mem1))
		if [[ $mem1 -eq 0 ]]; then
			impr=
		else
			impr=$(((1.0*$diff/mem1)*100))
		fi
		echo "<td class=$c>$(printf "%+.2f" $diff)</td>"
		mdiffs="$mdiffs$diff\n"

		if [[ -n "$impr" ]]; then
			echo -n "<td class=$c>$(printf "%+.2f%%" $impr)"
			mimprs="$mimprs$impr\n"
		else
			echo -n "<td class=$c>inf%"
		fi
	fi
	echo "</td>"

	echo "</tr>"
	echo >&2
done
echo "</tbody>"

function withclassdiff {
	if [[ $1 -eq 0 ]]; then
		echo "<td>$1$2</td>"
	else
		if [[ $1 -lt 0 ]]; then
			c=g
		else
			c=b
		fi
		echo "<td class=$c>$1$2</td>"
	fi
}
function mean {
	echo "$1" | awk '{s+=$1}END{print s/NR}'
}
function median {
	echo "$1" | awk '{v[NR]=$1}END{asort(v);if(NR%2)print v[(NR+1)/2];else print (v[NR/2+1]+v[NR/2])/2;}'
}

cat <<EOF
<tbody>
<tr><td colspan=3>Mean difference and improvement</td>
EOF

diff=$(mean "$diffs")
impr=$(mean "$imprs")
withclassdiff $(printf "%+.3f" $diff)
withclassdiff $(printf "%+.2f" $impr) %

echo "<td colspan=2></td>"

diff=$(mean "$mdiffs")
impr=$(mean "$mimprs")
withclassdiff $(printf "%+.3f" $diff)
withclassdiff $(printf "%+.2f" $impr) %

echo "<tr><td colspan=3>Median difference and improvement</td>"

diff=$(median "$diffs")
impr=$(median "$imprs")
withclassdiff $(printf "%+.2f" $diff)
withclassdiff $(printf "%+.2f" $impr) %

echo "<td colspan=2></td>"

diff=$(median "$mdiffs")
impr=$(median "$mimprs")
withclassdiff $(printf "%+.2f" $diff)
withclassdiff $(printf "%+.2f" $impr) %

cat <<EOF
</td>
</tr>
</tbody>
</table>
EOF
echo -n "Generated at "
date +'%F %T (%Z = %:::z)'
echo "</body></html>"
