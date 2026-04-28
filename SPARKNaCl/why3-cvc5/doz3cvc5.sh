#!/bin/zsh
for I in *.smt2
do
   RZ=`z3 -T:5 $I`
   R5=`cvc5 --tlimit=5000 $I`
   echo $I "z3" $RZ "cvc5" $R5
   echo $I "z3" $RZ "cvc5" $R5 >>resz3cvc5.txt
done
