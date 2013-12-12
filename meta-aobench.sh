#!/bin/bash

function bench_smlnj () {
	sml @SMLload=aobench-image aobench-nj.ppm
}

function bench_mlton () {
	./aobench-mlton aobench-mlton.ppm
}

function bench_gcc () {
	./aobench-c aobench-c.ppm
}

function bench_smlsharp () {
	./aobench-smlsharp aobench-smlsharp.ppm
}

# number of iteration
N=3

# comparative criterion
which gcc >/dev/null 2>&1
if [ $? -eq 0 ]; then
	gcc -std=gnu99 -O2 -Wall --pedantic-errors -o aobench-c aobench.c -lm
	time for (( i=0; i<$N; i++ )); do bench_gcc; done
fi
echo ""

which sml >/dev/null 2>&1
if [ $? -eq 0 ]; then
	ml-build aobench.cm AObench.main aobench-image
	time for (( i=0; i<$N; i++ )); do bench_smlnj; done
fi
echo ""

which mlton >/dev/null 2>&1
if [ $? -eq 0 ]; then
	mlton -output aobench-mlton aobench.mlb
	time for (( i=0; i<$N; i++ )); do bench_mlton; done
fi
echo ""

which smlsharp >/dev/null 2>&1
if [ $? -eq 0 ]; then
	make -f makefile-smlsharp
	time for (( i=0; i<$N; i++ )); do bench_smlsharp; done
fi

