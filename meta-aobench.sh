#!/bin/bash

function bench_smlnj () {
	sml @SMLload=aobench-image.x86-cygwin aobench-nj.ppm
}

function bench_mlton () {
	./aobench aobench-mlton.ppm
}

function bench_gcc () {
	./aobench-c
}

time for (( i=0; i<10; i++ )); do
	bench_smlnj
done
time for (( i=0; i<10; i++ )); do
	bench_mlton
done
time for (( i=0; i<10; i++ )); do
	bench_gcc
done



