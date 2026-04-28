#!/usr/bin/env bash
B=`basename $1 .smt2`
R=`cvc5 --rlimit-per=1000000 $1`
if [ "$R" = "unsat" ]; then
    echo $1 "unsat(DEF)"
    echo $1 "unsat(DEF)" >$B.p5res
else
    R=`cvc5 --rlimit-per=5000000 --miniscope-quant=off $1`
    if [ "$R" = "unsat" ]; then
        echo $1 "unsat(MQO)"
        echo $1 "unsat(MQO)" >$B.p5res
    else
        R=`cvc5 --rlimit-per=5000000 --decision=internal $1`
        if [ "$R" = "unsat" ]; then
            echo $1 "unsat(DI)"
            echo $1 "unsat(DI)" >$B.p5res
        else
            R=`cvc5 --rlimit-per=5000000 --enum-inst-interleave $1`
            if [ "$R" = "unsat" ]; then
                echo $1 "unsat(EII)"
                echo $1 "unsat(EII)" >$B.p5res
            else
                R=`cvc5 --rlimit-per=5500000 --finite-model-find --enum-inst $1`
                if [ "$R" = "unsat" ]; then
                    echo $1 "unsat(FMFEI)"
                    echo $1 "unsat(FMFEI)" >$B.p5res
                else
                    echo $1 "timeout(ALL)"
                    echo $1 "timeout(ALL)" >$B.p5res
                fi
            fi
        fi
    fi
fi
