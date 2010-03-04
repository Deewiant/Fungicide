#!/bin/zsh -G
rm -rf plots/probsize/*
cat runs.dat | awk '{print $1}' | xargs -n1 basename | sed 's/\.[^.]*$//' | xargs -n1 ./plot-probsize.sh | fgrep .eps... | cut '-d ' -f7 | sed 's/...$//' | while read -r f; do mv -v $f plots/probsize; done
