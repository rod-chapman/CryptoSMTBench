#!/bin/zsh
for I in *.smtcp
do
   J=`basename $I .smtcp`
   echo Renaming $J.smtcp to $J.smt2
   mv $J.smtcp $J.smt2
done
