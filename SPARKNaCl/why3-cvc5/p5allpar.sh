#!/bin/zsh
ls *.smt2 | parallel -j8 --bar ./cvc5p5.sh {}
cat *.p5res | sort >all.p5res
