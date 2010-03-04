#!/bin/bash

if [[ -z "$1" || -z "$2" ]]; then
	echo "Usage: $0 <interp> <interp> [benchmark]" >&2
	exit 1
fi

if [[ ! -d data/$1 ]]; then
	echo "$1 doesn't look like an interp..." >&2
fi
if [[ ! -d data/$2 ]]; then
	echo "$2 doesn't look like an interp..." >&2
fi
if [[ ! -d data/$1 || ! -d data/$2 ]]; then
	exit 2
fi

tmpdir=$(mktemp -td)

if [[ -n "$3" ]]; then
	if [[ ! -f data/$1/$3/memtime || ! -f data/$2/$3/memtime ]]; then
		echo "One or both don't have $3..." >&2
		exit 2
	fi
	cat data/$1/$3/memtime data/$1/$3/time | sort -gr | sed 1d >> $tmpdir/$1
	cat data/$2/$3/memtime data/$2/$3/time | sort -gr | sed 1d >> $tmpdir/$2
	echo "Got $(wc -l < data/$1/$3/time)/$(wc -l < data/$2/$3/time) from $3..."
else
	n=0
	for d in data/$1/*; do
		bm=$(basename $d)
		if [[ -f data/$1/$bm/memtime && -f data/$2/$bm/memtime ]]; then
			cat data/$1/$bm/memtime data/$1/$bm/time | sort -gr | sed 1d >> $tmpdir/$1
			cat data/$2/$bm/memtime data/$2/$bm/time | sort -gr | sed 1d >> $tmpdir/$2
			echo "Got $(wc -l < data/$1/$bm/time)/$(wc -l < data/$2/$bm/time) from $bm..."
			(( ++n ))
		else
			echo "Skipping $bm, one or both don't have it..."
		fi
	done
	echo "Using data from $n benchmarks..."
fi
pushd $tmpdir >/dev/null
ministat -a -m -s -w 76 $1 $2
popd >/dev/null
rm -rf $tmpdir
