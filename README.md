# Numbers to reproduce
This artifact is for reproducing the numbers from Figure 13 (TSVC), Figure 15 (PolyBench), and Figure 16 (ISPC).
On my mac, the geomean over LLVM on TSVC is 0.996.
On PolyBench it's 1.3x over LLVM.
On ISPC the geoman speedup is 2.0x over LLVM.

# Dependences
You need docker and a machine with AVX-512.

# Build instruction
You should be able to run `docker build -t vegen-pldi22-ae .` to build everything from source.
In the docker file, I use `make -j72` to build LLVM from source, and you may want to adjust the level of build parallelism to suit your CPU.
Because the docker build also runs some of the benchmark automatically for you, please don't run other
stuff in the background (so that the measurements are not affected).

# Running the benchmarks
Once you've build the docker image, enter interactive mode the following command before running the benchmarks.
```bash
docker run -it vegen-pldi22-ae /bin/bash
```

## TSVC 
If you build the docker image from scratch on your machine, TSVC should be automatically benchmarked
and the results in `/tsvc-vegen.txt` and `/tsvc-llvm.txt`.
To compare the results, use the following command
```bash
python3 get-tsvc-speedup.py tsvc-llvm.txt tsvc-vegen.txt
```

Do the following if you want to rerun the benchmarks.
```bash
# optimize tsvc with our vectorizer (vegen)
cd /tsvc-vegen
make clean
CC=vegen-clang make

# optimize tsvc with clang's vectorizer
cd /tsvc-llvm
make clean
CC=clang make

# run the benchmarks
cd /
/tsvc-vegen/runvec > tsvc-vegen.txt
/tsvc-llvm/runvec > tsvc-llvm.txt

# compare the numbers
python3 get-tsvc-speedup.py tsvc-llvm.txt tsvc-vegen.txt
```

## PolyBench
The docker build should automatically run the benchmarks for you and dump the results to `/polybench-vegen.csv` (our results),
`/polybench-llvm.csv` (results from using LLVM's vectorizer), and `/polybench-scalar.csv` (results from using LLVM `-O3` without vectorization).
Use the script `/get-polybench-speedup.py` to compare the numbers.
For example, the following command shows the speedup of our vectorizer (vegen) over llvm's vectorizer.
```
cd /
python3 get-polybench-speedup.py polybench-llvm.csv polybench-vegen.csv
```

Do the following if you want to rerun the benchmarks.
```bash
cd /
python3 run-polybench.py polybench-vegen polybench-vegen.csv
python3 run-polybench.py polybench-llvm polybench-llvm.csv
python3 run-polybench.py polybench-scalar polybench-scalar.csv
```

# ISPC
Because there are only six ISPC benchmarks, I don't have a script. Just do the following to get the numbers.
```bash
cd /ispc-bench
# aobench
make run-ao
# ray tracker
make run-rt
# binomial options *and* black scholes (they are bundled together)
make run-options
# stencil
make run-stencil
# mandelbrot
make run-mandelbrot
# volume
make run-volume
```
