#!/bin/zsh -G

TIMEOUT=10800

if [[ -z "$1" ]]; then
	echo "Usage: $0 <preprocessed benchmark-param dir> [tmp dir prefix]" >&2
	exit 1
fi
tf=$1/time
mf=$1/mem
rf=$1/runs

tmpd=${2}tmp/tablespec
mkdir -p $tmpd

cat <<EOF
<table>
<thead><tr>
<th scope="col">Interpreter</th>
<th scope="col">Ran</th>
<th scope="col">Mean time</th>
<th scope="col">Maximum memory</th>
<th scope="col">Time ratio</th>
<th scope="col">Memory ratio</th>
</tr></thead>
<tbody>
EOF

join <(sort $rf) <(sort $tf) > $tmpd/tmp || exit 2
join $tmpd/tmp <(sort $mf) > $tmpd/tmp2 || exit 2
fgrep -vw timeout $tmpd/tmp2 > $tmpd/tmp
cat <(sort -gk3,3 $tmpd/tmp) <(fgrep -w timeout $tmpd/tmp2 | sort -gk4,4) > $tmpd/tmp3
last=$tmpd/tmp3

mint=$(head -n1 $last | cut '-d ' -f3)
awk 'NR==1{m=$4}NR>1{if($4<m)m=$4}END{print m}' $last | read -r minm

wrap() {
	if [[ "$1" = "$2" ]]; then
		printf '<strong>%.2f</strong>' $1
	elif [[ $1 = timeout ]]; then
		echo timeout
	else
		printf %.2f $1
	fi
}
ratio() {
	if [[ $1 = timeout ]]; then
		echo timeout
	else
		printf "%.2f" $((($1+0.0) / $2))
	fi
}

< $last | while read -r i n t m; do
	echo -n "<tr><th scope=\"row\">$i</th><td>$n</td>"
	echo -n "<td>$(wrap $t $mint)</td>"
	echo -n "<td>$(wrap $m $minm)</td>"
	echo -n "<td>$(ratio $t $mint)</td>"
	echo -n "<td>$(ratio $m $minm)</td>"
	echo "</tr>"
done
echo "</tbody></table>"
