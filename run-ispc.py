import sys
import os
import subprocess
from collections import OrderedDict

def extract_bracket(s):
  return s[s.index('[')+1 : s.index(']')]

def run(cmd, timings):
  out = subprocess.check_output(cmd.split())
  for line in out.decode().strip().split('\n'):
    if line.startswith('['):
      lhs, rhs = line.split(':')
      timings[extract_bracket(lhs)] = float(extract_bracket(rhs))

def compare(ref_timings, test_timings):
  speedup = 1.0
  benches = list(test_timings.keys())
  for bench in benches:
    ref = ref_timings[bench]
    test = test_timings[bench]
    print(bench, ':', ref/test)
    speedup *= ref/test
  print('GeoMean:', speedup ** (1/len(benches)))

ispc_dir = sys.argv[1]
os.chdir(ispc_dir)

# Build the benchmarks
subprocess.call(['make'])

# Benchmark code optimized with our vectorizer
vegen_timings = OrderedDict()
run('./ao.vegen 500 500', vegen_timings)
run('./rt.vegen sponza', vegen_timings)
run('./options.vegen sponza', vegen_timings)
run('./stencil.vegen', vegen_timings)
run('./mandelbrot.vegen', vegen_timings)
run('./volume.vegen camera.dat density_lowres.vol', vegen_timings)

# Benchmark code optimized with llvm's vectorizer
llvm_timings = OrderedDict()
run('./ao.llvm 500 500', llvm_timings)
run('./rt.llvm sponza', llvm_timings)
run('./options.llvm sponza', llvm_timings)
run('./stencil.llvm', llvm_timings)
run('./mandelbrot.llvm', llvm_timings)
run('./volume.llvm camera.dat density_lowres.vol', llvm_timings)

# Report the speedup over llvm
compare(llvm_timings, vegen_timings)
