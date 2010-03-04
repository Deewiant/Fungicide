#!/bin/zsh

if [[ -z "$1" || -z "$2" ]]; then
	echo "Usage: $0 <line in interpreters.dat> <line in runs.dat>" >&2
	exit 1
fi
intfull=$(sed -n $1p interpreters.dat)
run=$(sed -n $2p runs.dat)

if [[ -n "$(echo "$intfull" | grep '^#')" || -n "$(echo "$run" | grep '^#')" ]]; then
	echo COMMENTEDOUT
	exit 0
fi

file=$(echo $run | awk '{print $1}')
n=$(echo $run | awk '{print NF}')

if [[ ! -f "$file" ]]; then
	echo FILENOTFOUND
	exit 3
fi

int=$(echo $intfull | awk '{print $1}')
intcmd=$(echo $intfull | awk '{printf"%s",$2;for(i=3;i<=NF;++i)printf" %s",$i;print""}')

mkdir -p tmp
tmp=$(mktemp -tp tmp $(basename $file).XXXX)

function run {
	targetdir=data/$int/$1

	if [[ -n "$2" ]]; then
		echo -n "  $2... "
	fi

	# memtime might be the only one there if it timed out
	if [[ ! -f $targetdir/memtime ]]; then

		statdir=$(mktemp -tp tmp -d $(basename $tmp)-XXXX)

		./runone.pl "$statdir" "$tmp" $intcmd

		if [[ $? -ne 0 ]]; then
			echo ERROR
		else
			echo OK

			mkdir -p $targetdir
			mv $statdir/* $targetdir
		fi
		rm -rf $statdir
	else
		echo ALREADYDONE
	fi
}

if [[ $n -eq 1 ]]; then
	cp $file $tmp
	run $(basename $file) ''
else
	ext=${file##*.}
	extless=${file%.*}
	if [[ $ext = "bre" ]]; then
		for i in $(seq 2 $n); do
			rep=$(echo $run | awk "{print \$$i}")
			if ! ./bre.pl $rep < $file > $tmp; then
				echo "Generating $file-$rep failed! Skipping..." >&2
				continue
			fi
			run $(basename $extless-$rep) $rep
		done
	elif [[ $ext = "pl" ]]; then
		for i in $(seq 2 $n); do
			rep=$(echo $run | awk "{print \$$i}")
			if ! perl $file $rep > $tmp; then
				echo "Generating $file-$rep failed! Skipping..." >&2
				continue
			fi
			run $(basename $extless-$rep) $rep
		done
	elif [[ $ext = "sh" ]]; then
		for i in $(seq 2 $n); do
			rep=$(echo $run | awk "{print \$$i}")
			if ! zsh $file $rep > $tmp; then
				echo "Generating $file-$rep failed! Skipping..." >&2
				continue
			fi
			run $(basename $extless-$rep) $rep
		done
	else
		echo "Extra columns for static file $file" >&2
		exit 2
	fi
fi

echo
rm -f $tmp
