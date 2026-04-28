#!/usr/bin/env bash
C=`nproc`
ls *.smt2 | parallel -j$C --bar ./cvc5p5seqr.sh {}
cat *.p5res | sort >allr.res
