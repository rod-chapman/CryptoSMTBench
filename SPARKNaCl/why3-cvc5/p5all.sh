#!/usr/bin/env bash
C=`nproc`
ls *.smt2 | parallel -j$C --bar ./cvc5p5seq.sh {}
cat sparknacl*.p5res | sort >allseq.p5res
