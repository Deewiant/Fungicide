#!/bin/zsh -G

TIMEOUT=10800

if [[ -z "$1" || -z "$2" ]]; then
	echo "Usage: $0 <preprocessed time data> <preprocessed mem data>" >&2
	exit 1
fi
tf=$1
mf=$2

if [[ $(head -qn1 $tf) != $(head -qn1 $mf) ]]; then
	echo "ERROR :: header lines in $tf and $mf don't match, can't handle that" >&2
	exit 2
fi

tmpd=tmp/tablesum
mkdir -p $tmpd

cat <<EOF
<table>
<thead><tr>
<th scope="col">Interpreter</th>
<th scope="col">Ran</th>
<th scope="col">Total time</th>
<th scope="col">Total memory</th>
<th scope="col">Time ratio</th>
<th scope="col">Memory ratio</th>
<th scope="col">Maximum time</th>
<th scope="col">Maximum memory</th>
<th scope="col">Time ratio</th>
<th scope="col">Memory ratio</th>
</tr></thead>
<tbody>
EOF

cols=$(head -qn1 $tf | awk -F, '{print NF}')

rm -f $tmpd/{{t,m}{m,s},ss}
for c in $(seq 1 $cols); do
	i=$(head -qn1 $tf | cut -d, -f$c)
	sed 1d $tf | awk -F, "\$$c!=\"\"{++n;if(\$$c==\"timeout\")s+=$TIMEOUT;else s+=\$$c;if(\$$c>m)m=\$$c}END{print n,s,m}" | read -r succ sum max
	echo $i $succ >> $tmpd/ss
	echo $i $sum >> $tmpd/ts
	echo $i $max >> $tmpd/tm
	sed 1d $mf | awk -F, "{s+=\$$c;if(\$$c>m)m=\$$c}END{print s,m}" | read -r sum max
	echo $i $sum >> $tmpd/ms
	echo $i $max >> $tmpd/mm
done
join $tmpd/ss $tmpd/ts  > $tmpd/tmp
join $tmpd/tmp $tmpd/ms > $tmpd/tmp2
join $tmpd/tmp2 $tmpd/tm > $tmpd/tmp
join $tmpd/tmp $tmpd/mm | sort -gk3,3 | sort -nsrk2,2 > $tmpd/tmp2
last=$tmpd/tmp2

mintsum=$(head -n1 $last | cut '-d ' -f3)
awk 'NR==1{m4=$4;m5=$5;m6=$6}NR>1{if($4<m4)m4=$4;if($5<m5)m5=$5;if($6<m6)m6=$6}END{print m4,m5,m6}' $last \
	| read -r minmsum mintmax minmmax

wrap() {
	if [[ "$1" = "$2" ]]; then
		printf '<strong>%.1f</strong>' $1
	elif [[ $1 = timeout ]]; then
		echo timeout
	else
		printf %.1f $1
	fi
}
ratio() {
	if [[ $1 = timeout ]]; then
		echo timeout
	else
		printf "%.2f" $((($1+0.0) / $2))
	fi
}

< $last | while read -r i n tsum msum tmax mmax; do
	echo -n "<tr><th scope=\"row\">$i</th><td>$n</td>"
	echo -n "<td>$(wrap $tsum $mintsum)</td>"
	echo -n "<td>$(wrap $msum $minmsum)</td>"
	echo -n "<td>$(ratio $tsum $mintsum)</td>"
	echo -n "<td>$(ratio $msum $minmsum)</td>"
	echo -n "<td>$(wrap $tmax $mintmax)</td>"
	echo -n "<td>$(wrap $mmax $minmmax)</td>"
	echo -n "<td>$(ratio $tmax $mintmax)</td>"
	echo -n "<td>$(ratio $mmax $minmmax)</td>"
	echo "</tr>"
done
echo "</tbody></table>"
