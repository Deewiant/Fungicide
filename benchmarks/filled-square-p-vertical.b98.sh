if [[ -z "$1" || $(($1 % 2)) -ne 0 ]]; then
	exit 1
fi
cat <<EOF
;v;$(fungify $1)40p50p'v:60p70p'>80p90p ;40 is N, 50 is x, stack is y;;
 >60g50gfp>:70g\\50g\\f1++p:40g3-\\\`#v_\$80g50g40ge+p40g50g1+\`!#v_90g#v_v
          ^                     +1<            vp09p08>'p07p 06:v'< >'>60p'^:70p80p190pv
 ^                                     p05+1g05<                                       <
 v                                                          <
v>:'v\\40g\\f+p:40g4-\\\`#v_\$40g:'f\\:c+p:'.\\:d+p'@\\:e+p
 ^                  +1<
EOF
