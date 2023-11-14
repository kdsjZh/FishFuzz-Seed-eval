#!/usr/bin/python3


import os
import subprocess 
import argparse
from argparse import ArgumentTypeError as ArgTypeErr


fuzzer_list = ['ffapp', 'ffexp', 'aflpp']
benchmark_list = ['wireshark']

def docker_extract_all_trial(results_dir, n_trial):
  # docker cp wireshark_aflpp_4:/work/default $RESULTS/wireshark/aflpp/4
  for benchmark in benchmark_list:
    for fuzzer in fuzzer_list:
      for trial in range(n_trial):
        print ('docker cp %s_%s_%d:/work/default %s/%s/%s/%d' % \
              (benchmark, fuzzer, trial, results_dir, benchmark, fuzzer, trial))


def check_out_dir(results_dir, n_trial):
  if not os.path.isdir(results_dir):
    os.mkdir(workdresults_dirir)
  for bench in benchmark_list:
    bench_dir = '%s/%s' % (results_dir, bench)
    if not os.path.isdir(bench_dir):
      os.mkdir(bench_dir)
    for fuzzer in fuzzer_list:
      fuzzer_dir = '%s/%s' % (bench_dir, fuzzer)
      if not os.path.isdir(fuzzer_dir):
        os.mkdir(fuzzer_dir)
      for n in range(n_trial):
        trail_dir = '%s/%d' % (fuzzer_dir, n)
        if not os.path.isdir(trail_dir):
          os.mkdir(trail_dir) 

if __name__ == "__main__":
  parser = argparse.ArgumentParser()
  parser.add_argument("-r", help="results dir to share the evaluation results ")
  parser.add_argument("-n", help="number of trial")

  args = parser.parse_args()
  check_out_dir(args.r, int(args.n))
  docker_extract_all_trial(args.r, int(args.n))