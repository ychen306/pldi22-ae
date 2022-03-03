import sys

def parse(fname):
  with open(fname) as f:
    timings = {}
    for line in f:
      bench, elapsed = line.split(',')
      timings[bench] = float(elapsed)
    return timings

ref, test = sys.argv[1:]
ref_cycles = parse(ref)
test_cycles = parse(test)
product = 1
for bench in ref_cycles:
  speedup  = ref_cycles[bench] / test_cycles[bench]
  product *= speedup
  print(bench, speedup)
print('geomean', product ** (1/len(ref_cycles)))
