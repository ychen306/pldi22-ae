# import the baseimage*, which contains a copy of LLVM 12.0.1 (pre)built from source 
# * https://hub.docker.com/layers/clang/dsrcl/clang/pldi22-ae/images/sha256-c73481c08d09d5942ddc31e3656104055eadc4b92c4466081983734820e8cf31?context=explore
from dsrcl/clang:pldi22-ae

# Build the vectorizer
# This should take about 2 minutes on an 8-core machine and no longer than 10 minutes on a single core.
WORKDIR /
RUN git clone https://github.com/ychen306/vegen
RUN mkdir vegen/build
WORKDIR vegen/build
RUN git checkout pldi22-ae &&\
   touch arm.bc && cmake -DCMAKE_BUILD_TYPE=Release\
   -DCMAKE_PREFIX_PATH="/llvm-project-12.0.1.src/build"\
   -DCMAKE_CXX_COMPILER=/bin/clang++-12\
   ../ && make -j

ENV PATH="/vegen/build/:${PATH}"

# optimize the ispc benchmarks
WORKDIR / 
RUN git clone https://github.com/ychen306/ispc-bench
WORKDIR ispc-bench
RUN make all -j

# setup polybench
COPY run-polybench.py /run-polybench.py
WORKDIR /
RUN curl -L https://sourceforge.net/projects/polybench/files/polybench-c-4.2.tar.gz/download -o polybench.tar.gz &&\
      tar -xvf polybench.tar.gz &&\
      cp -r polybench-c-4.2 polybench-vegen &&\
      cp -r polybench-c-4.2 polybench-llvm &&\
      cp -r polybench-c-4.2 polybench-scalar &&\
      perl polybench-vegen/utilities/makefile-gen.pl polybench-vegen &&\
      perl polybench-vegen/utilities/makefile-gen.pl polybench-llvm &&\
      perl polybench-vegen/utilities/makefile-gen.pl polybench-scalar &&\
      rm -f polybench-vegen/config.mk &&\
      echo CFLAGS=-O3 -ffast-math -march=native -DPOLYBENCH_TIME -DPOLYBENCH_USE_RESTRICT >>polybench-vegen/config.mk &&\
      echo CC=vegen-clang >>polybench-vegen/config.mk &&\
      echo CFLAGS=-O3 -ffast-math -march=native -DPOLYBENCH_TIME -DPOLYBENCH_USE_RESTRICT >>polybench-llvm/config.mk &&\
      echo CC=clang >>polybench-llvm/config.mk &&\
      echo CFLAGS=-O3 -ffast-math -march=native -fno-vectorize -fno-slp-vectorize -DPOLYBENCH_TIME -DPOLYBENCH_USE_RESTRICT >>polybench-scalar/config.mk &&\
      echo CC=clang >>polybench-scalar/config.mk

# Optimize and run polybench.
# The following three steps runs our vectorizer, LLVm's vectorizers, and LLVM's -O3 without vectorization repsectively.
# Each step should take around 5 to 6 minutes.
RUN python3 run-polybench.py polybench-vegen polybench-vegen.csv
RUN python3 run-polybench.py polybench-llvm polybench-llvm.csv
RUN python3 run-polybench.py polybench-scalar polybench-scalar.csv

# get polybench speedup (you can also run this manually)
COPY get-polybench-speedup.py /get-polybench-speedup.py
# speed up over llvm's vectorizer
RUN python3 get-polybench-speedup.py polybench-llvm.csv polybench-vegen.csv
# speed up over llvm scalar -O3
RUN python3 get-polybench-speedup.py polybench-scalar.csv polybench-vegen.csv

# optimize TSVC
COPY tsvc tsvc-vegen
COPY tsvc tsvc-llvm
WORKDIR /tsvc-vegen
# Optimize with our vectorizer. Should take about 30 seconds
RUN CC=vegen-clang make
WORKDIR /tsvc-llvm
# Optimize with LLVM's vectorizers. Should take about 30 seconds 
RUN CC=clang make

# run TSVC
WORKDIR /
# Run TSVC optimized with our vectorizer. Should take about 3 minutes for each step.
RUN /tsvc-vegen/runvec > tsvc-vegen.txt
RUN /tsvc-llvm/runvec > tsvc-llvm.txt

# get the speedup
COPY get-tsvc-speedup.py /get-tsvc-speedup.py
RUN python3 get-tsvc-speedup.py tsvc-llvm.txt tsvc-vegen.txt

# run ISPC benchmarks
COPY run-ispc.py /run-ispc.py
RUN python3 run-ispc.py ispc-bench
