#!/bin/zsh
for I in *.smt2
do
   R5=`cvc5 --tlimit=5000 $I`
   echo $I $R5
   echo $I $R5 >>res.txt
done
echo "============================="
#echo "Timeouts and/or failures are:"
#grep -v "smt2 unsat" res.txt
