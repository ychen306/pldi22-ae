# Outline 
This artifact is for reproducing the numbers from Figure 13 (TSVC), Figure 14 (a motivating kernel from TSVC), Figure 15 (PolyBench), and Figure 16 (ISPC).
For convenience, I have saved the speedups from our local experiments in the files `tsvc-results.txt` (Figure 13 and 14), `polybench-results.txt` (Figure 15),
    and `ispc-results.txt` (Figure 16).

Overall, the geomean over LLVM on TSVC is 0.99.
The kernel from Figure 14 (from TSVC's s275) should be between 2.0x and 3.0x (depends on your machine).
On PolyBench it's 1.4x over LLVM.
On ISPC the geoman speedup is 1.5x over LLVM.

# Dependences
You need docker and a machine with AVX-512.

# Build instruction
Run the following command to build everything from source, which should take no longer than an hour.
To save time, we are using a base image called `dsrcl/clang:pldi22-ae`,
which is a base docker image
containing a copy of LLVM-12 rebuilt from source and doesn't do anything special
(you can verify [here](https://hub.docker.com/layers/clang/dsrcl/clang/pldi22-ae/images/sha256-c73481c08d09d5942ddc31e3656104055eadc4b92c4466081983734820e8cf31?context=explore)).
```bash
docker build -t vegen-pldi22-ae .
```
Because the docker build also runs some of the benchmark automatically for you, please don't run other
stuff in the background (so that the measurements are not affected).
This should take between 40 to 60 minutes.

# Running the benchmarks
Once you've build the docker image, enter interactive mode the following command before running the benchmarks.
```bash
docker run -it vegen-pldi22-ae /bin/bash
```

## TSVC (Figure 13)
If you build the docker image from scratch on your machine, TSVC should be automatically benchmarked
and the results in `/tsvc-vegen.txt` and `/tsvc-llvm.txt`.
To compare the results, use the following command
```bash
python3 get-tsvc-speedup.py tsvc-llvm.txt tsvc-vegen.txt
```
The script shows you the geomean and the individual speedup for the different kernels. The kernel in Figure 14 comes from kernel s275.

Do the following if you want to rerun the benchmarks and calculate the speedup; this should take about 10 minutes.
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
For comparison, the result I got on my machine is in the file `tsvc-results.txt`.

## PolyBench (Figure 15)
The docker build should automatically run the benchmarks for you and dump the results to `/polybench-vegen.csv` (our results),
`/polybench-llvm.csv` (results from using LLVM's vectorizer).
Use the following command to get the speedup.
```
cd /
python3 get-polybench-speedup.py polybench-llvm.csv polybench-vegen.csv
```

Do the following if you want to rerun the benchmarks, which should take about 15 minutes.
```bash
cd /
python3 run-polybench.py polybench-vegen polybench-vegen.csv
python3 run-polybench.py polybench-llvm polybench-llvm.csv
# Get the speedup
python3 get-polybench-speedup.py polybench-llvm.csv polybench-vegen.csv
```
For comparison, the result I got on my machine is in the file `polybench-results.txt`.

# ISPC (Figure 16)
Run the following script to build and run the ISPC benchmarks (the script also reports speedup).
This step should take about 20 seconds.
```
python3 run-ispc.py ispc-bench
```
For comparison, the result I got on my machine is in the file `ispc-results.txt`.
