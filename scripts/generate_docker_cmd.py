#!/usr/bin/python3


import os
import subprocess 
import argparse
import multiprocessing as mp
from argparse import ArgumentTypeError as ArgTypeErr

# number of physical cores, we don't want to use logical 
MAXIUM_CORES=16

fuzzer_list = ['ffafl', 'aflpp']
benchmark_list = ['wireshark']

def construct_docker_cmd(workdir, fuzzer_name, benchmark_name, bind_cpu_id, n_trial, timeout):
  docker_cmd = 'docker run -dt ' 
  docker_cmd += '-v %s/%s/%s/%d:%s ' % (workdir, benchmark_name, fuzzer_name, n_trial,  "/out")
  docker_cmd += '--name %s_%s_%d ' % (benchmark_name, fuzzer_name, n_trial)
  docker_cmd += '--cpuset-cpus %d ' % (bind_cpu_id)
  # make sure current user have access to shared dir without root privilage
  # for tic's permission, disable this feature
  # docker_cmd += '--user $(id -u $(whoami)) --privileged '
  docker_cmd += 'fishfuzz/eval-large:%s ' % (benchmark_name)
  docker_cmd += '"timeout -s KILL --preserve-status %s /out/%s/run.sh"' % (timeout, fuzzer_name)
  return docker_cmd

def docker_run_all_trial(workdir, n_trial, timeout):
  # assuming all cpus are free
  used_cores = mp.cpu_count()
  if used_cores > MAXIUM_CORES:
    used_cores = MAXIUM_CORES
  cpuid = 0
  for benchmark in benchmark_list:
    for fuzzer in fuzzer_list:
      for trial in range(n_trial):
        if cpuid and cpuid % used_cores == 0:
          print ('---------------------------------This is a new round---------------------------------')
        docker_cmd = construct_docker_cmd(workdir, fuzzer, benchmark, cpuid % used_cores, trial, timeout)
        # replace with subprocess.run later
        print (docker_cmd)
        cpuid += 1

def check_out_dir(workdir, n_trial):
  if not os.path.isdir(workdir):
    os.mkdir(workdir)
  for bench in benchmark_list:
    bench_dir = '%s/%s' % (workdir, bench)
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
  parser.add_argument("-w", help="workdir to share the evaluation results ")
  parser.add_argument("-t", help="evaluation timeout")
  parser.add_argument("-n", help="number of trial")

  args = parser.parse_args()
  check_out_dir(args.w, int(args.n))
  docker_run_all_trial(args.w, int(args.n), args.t)