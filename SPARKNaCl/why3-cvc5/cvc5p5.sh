#!/usr/bin/env bash
R1=`cvc5 --tlimit=5000 $1`
R2=`cvc5 --tlimit=40000 --finite-model-find --enum-inst $1`
R3=`cvc5 --tlimit=20000 --enum-inst-interleave $1`
R4=`cvc5 --tlimit=20000 --decision=internal $1`
R5=`cvc5 --tlimit=20000 --miniscope-quant=off $1`
echo $1,$R1,$R2,$R3,$R4,$R5
B=`basename $1 .smt2`
echo $1,$R1,$R2,$R3,$R4,$R5 >$B.p5res
