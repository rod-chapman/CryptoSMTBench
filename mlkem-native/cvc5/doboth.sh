#!/bin/zsh
for I in *.smt2
do
   RZ=`z3 -T:20 $I`
   R5=`cvc5 --tlimit=20000 --arrays-exp --enum-inst $I`
   echo $I "z" $RZ "c" $R5
   echo $I "z" $RZ "c" $R5 >>resboth.txt
done
