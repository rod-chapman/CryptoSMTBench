#!/usr/bin/env bash
B=`basename $1 .smt2`
OPTS="trace=true trace_file_name=$B.txt3 -v:0 suppress_platform_verbose=true parallel.enable=false smt.threads=1 sat.threads=1 smt.sls.parallel=false smt.random_seed=0 sat.random_seed=0 nlsat.seed=0 rlimit=1000000"
z3 $OPTS $1 >$B.txt1 2>$B.txt2
