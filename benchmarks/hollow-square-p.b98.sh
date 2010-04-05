if [[ -z "$1" ]]; then
	exit 1
fi
cat <<EOF
;v;$(fungify $1):30p1-40p;
v>:'>\\fp:40g\\\`#v_\$1>:'v\\e+40g\\p:30g\\\`#v_\$40g>:'<\\30ge+p:#v_\$30ge+>:'^\\0\p:f3+\`#v_\$'f0f3+p'.0f2+p'@0f1+p
 ^           +1<   ^                +1<     ^          -1<       ^           -1<
EOF
