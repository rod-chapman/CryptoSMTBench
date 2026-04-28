#!/usr/bin/env bash
C=`nproc`
ls *.smt2 | parallel -j$C --bar ./cvc5p5seq.sh {}
cat *.p5res | sort >all.p5res
