import os
import sys
import subprocess

bench_dirs = [
    './datamining/covariance',
    './datamining/correlation',
    './medley/deriche',
    './medley/floyd-warshall',
    './medley/nussinov',
    './stencils/adi',
    './stencils/seidel-2d',
    './stencils/jacobi-2d',
    './stencils/heat-3d',
    './stencils/jacobi-1d',
    './stencils/fdtd-2d',
    './linear-algebra/kernels/3mm',
    './linear-algebra/kernels/doitgen',
    './linear-algebra/kernels/2mm',
    './linear-algebra/kernels/bicg',
    './linear-algebra/kernels/atax',
    './linear-algebra/kernels/mvt',
    './linear-algebra/blas/symm',
    './linear-algebra/blas/gemver',
    './linear-algebra/blas/gemm',
    './linear-algebra/blas/trmm',
    './linear-algebra/blas/gesummv',
    './linear-algebra/blas/syrk',
    './linear-algebra/blas/syr2k',
    './linear-algebra/solvers/durbin',
    './linear-algebra/solvers/trisolv',
    './linear-algebra/solvers/gramschmidt',
    './linear-algebra/solvers/cholesky',
    './linear-algebra/solvers/lu',
    './linear-algebra/solvers/ludcmp',
    ]

orig_dir = os.getcwd()

base_dir, results_f = sys.argv[1:]
base_dir = orig_dir + '/' + base_dir

def run_bench(bench_dir):
  os.chdir(base_dir)
  os.chdir(bench_dir)
  subprocess.check_call(['make', 'clean'], stderr=subprocess.DEVNULL)
  subprocess.check_call(['make'], stderr=subprocess.DEVNULL)
  bench_name = os.path.basename(bench_dir)
  out = subprocess.check_output([f'./{bench_name}'])
  os.chdir(base_dir)
  print(bench_name, float(out))
  return float(out)

timings = []
benches = []
for bench_dir in bench_dirs:
  bench = os.path.basename(bench_dir)
  print('Running', bench)
  elapsed = run_bench(bench_dir)
  benches.append(bench)
  timings.append(elapsed)

os.chdir(orig_dir)

with open(results_f, 'w') as f:
  for bench, elapsed in zip(benches, timings):
    f.write(bench)
    f.write(',')
    f.write(str(elapsed))
    f.write('\n')
