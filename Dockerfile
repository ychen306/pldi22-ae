from clangbuiltlinux/ubuntu:llvm12-latest

ENV CC /bin/clang-12
ENV CXX /bin/clang++-12

RUN apt-get update && apt-get install -y cmake

RUN curl -L https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.1/llvm-project-12.0.1.src.tar.xz -o llvm-project.tar.gz
 
RUN tar -xvf llvm-project.tar.gz

RUN apt-get install -y python3

# build llvm from source 
WORKDIR llvm-project-12.0.1.src
RUN mkdir build
WORKDIR build
RUN cmake -DLLVM_ENABLE_PROJECTS='clang'\
  -DLLVM_TARGETS_TO_BUILD=X86\
  -DCMAKE_BUILD_TYPE=Release\
  -DLLVM_ENABLE_ASSERTIONS=On\
  -DLLVM_ENABLE_TERMINFO=OFF\
  ../llvm && make -j72

RUN make install

# build the vectorizer
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

# optimize and run polybench
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
RUN CC=vegen-clang make
WORKDIR /tsvc-llvm
RUN CC=clang make

# run TSVC
WORKDIR /
RUN /tsvc-vegen/runvec > tsvc-vegen.txt
RUN /tsvc-llvm/runvec > tsvc-llvm.txt

# get the speedup
COPY get-tsvc-speedup.py /get-tsvc-speedup.py
RUN python3 get-tsvc-speedup.py tsvc-llvm.txt tsvc-vegen.txt
