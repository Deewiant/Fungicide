#!/bin/zsh
for f in data/*/*; do if [[ -f $f/time && -f $f/memtime ]]; then mt=$(cat $f/memtime); tt=$(awk 'NR==1{m=$1}NR>1{if($1>m)m=$1}END{print m}' $f/time); if [[ $mt -ge 1 && $((mt/2)) -gt $tt ]]; then printf "%60s " $f; echo -n "$mt "; paste -sd' ' $f/time; fi; fi; done 
