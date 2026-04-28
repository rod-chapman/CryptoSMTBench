#!/usr/bin/env bash
for I in *.smt2
do
   R5=`z3 -T:5 $I`
   echo $I $R5
   echo $I $R5 >>resz.txt
done
echo "============================="
#echo "Timeouts and/or failures are:"
#grep -v "smt2 unsat" resz.txt
