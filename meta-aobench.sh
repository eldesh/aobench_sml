#!/bin/bash

function bench () {
	case "$1" in
	sml)
		sml @SMLload=aobench-image aobench-sml.ppm
		;;
	gcc | mlton | mlkit | poly)
		./aobench-${1} aobench-${1}.ppm
		;;
	smlsharp)
		if [ -n "$2" ]; then
			MYTH_NUM_WORKERS=$2 ./aobench-${1}-par aobench-${1}-par.ppm 4
		else
			./aobench-${1} aobench-${1}.ppm
		fi
		;;
	mpl)
		./aobench-${1} @mpl procs 4 set-affinity -- aobench-${1}.ppm 4
		;;
	*)
		echo "unkown compiler [$1]"
		;;
	esac
}

function build () {
	case "$1" in
	sml)
		ml-build aobench.cm AObench.main aobench-image
		;;
	gcc)
		gcc -std=gnu99 -O2 -Wall --pedantic-errors -o aobench-gcc aobench.c -lm
		;;
	mlton)
		mlton -output aobench-mlton aobench.mlb
		;;
	mlkit)
		mlkit -output aobench-mlkit aobench-mlkit.mlb
		;;
	smlsharp)
		make -f makefile-smlsharp
		;;
	poly)
		make -f makefile-poly
		;;
	mpl)
		mpl -output aobench-mpl aobench-mpl.mlb
		;;
	*)
		echo "unkown compiler [$1]"
		;;
	esac
}


# number of iteration
N=1

compiler=(gcc sml mlton mlkit smlsharp poly mpl)
for (( i=0; i<${#compiler[@]}; i++ ))
do
	# check existence
	which ${compiler[$i]} >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		build ${compiler[$i]}
		if [ $? -ne 0 ]; then
			echo "building with ${compiler[$i]} failed" >&2
			continue
		fi

		echo "${compiler[$i]} is running"
		time for (( j=0; j<$N; j++ ))
		do
			bench ${compiler[$i]}
		done

		if [ ${compiler[$i]} = smlsharp ]; then
			time for (( j=0; j<$N; j++ ))
			do
				bench smlsharp 4
			done
		fi
	else
		echo "${compiler[$i]} is not found :(" >&2
	fi
done

