#!/usr/bin/python3

import argparse
from matplotlib import pyplot

MAXIUM_TIME_H = 24
SAMPLING_FREQ_M = 15
DATA_LEN = int(MAXIUM_TIME_H * 60 / SAMPLING_FREQ_M)
time_x_axis = [i * SAMPLING_FREQ_M * 60 for i in range(DATA_LEN)]

fuzzer_list = ['ffapp', 'aflpp']
benchmark_list = ['wireshark']
fuzzer_color = {'ffapp': 'orange', 'aflpp': 'green'}

'''
  Parse a plot_data log and return time to coverage
  we log every 15min
'''
def parse_one_log(fname, log_type = 'cov'):
  y_axis = []
  time_counter = 0
  with open(fname) as f:
    for line in f:
      if line.startswith('# '):
        continue
      time, cycle, cur, queued, pending, pending_fav, \
      bitmap_cvg, _, _, _, _, total_execs, edges = line.strip('\n').split(', ')
      cur_time = int(time)
      if cur_time >= time_x_axis[time_counter]:
        if log_type == 'cov':
          y_axis.append(int(edges))
        elif log_type == 'queue':
          y_axis.append(int(queued))
        elif log_type == 'execs':
          y_axis.append(int(total_execs))
        time_counter += 1
      if time_counter == DATA_LEN:
        break
  if len(y_axis) < DATA_LEN:
    print ('ERROR: %s\'s data len not match' % (fname))
    exit (-1)
  return y_axis[:DATA_LEN]


def plot_benchmark_n_trails(bench_results_dir, n_trial):
  all_cov = dict() 
  fuzzer_cov_pair = dict()
  for fuzzer in fuzzer_list:
    all_cov[fuzzer] = dict()
    best_among_trail = [0 for i in range(DATA_LEN)]
    worst_among_trail = [1000000 for i in range(DATA_LEN)]
    average_among_trail = [0 for i in range(DATA_LEN)]
    for trail in range(n_trial):
      log_path = '%s/%s/%d/default/plot_data' % (bench_results_dir, fuzzer, trail)
      all_cov[fuzzer][trail]  = parse_one_log(log_path)
      for i in range(DATA_LEN):
        average_among_trail[i] += all_cov[fuzzer][trail][i]
        if best_among_trail[i] < all_cov[fuzzer][trail][i]:
          best_among_trail[i] = all_cov[fuzzer][trail][i]
        if worst_among_trail[i] > all_cov[fuzzer][trail][i]:
          worst_among_trail[i] = all_cov[fuzzer][trail][i]
    for i in range(DATA_LEN):
      average_among_trail[i] /= n_trial
    fuzzer_cov_pair[fuzzer] = [best_among_trail, worst_among_trail, average_among_trail]
  return all_cov, fuzzer_cov_pair

def write_plot_bench(plot_name, fuzzer_cov_pair):
  pyplot.xlabel('fuzzing time (h)')
  pyplot.ylabel('coverage growth (aflpp edges)')
  x_axis = [i * SAMPLING_FREQ_M / 60 for i in range(DATA_LEN)]
  for fuzzer in fuzzer_cov_pair:
    best, worst, avg = fuzzer_cov_pair[fuzzer]
    pyplot.plot(x_axis, best, linestyle = 'dashed', color = fuzzer_color[fuzzer], label=f'{fuzzer} - best')
    pyplot.plot(x_axis, worst, linestyle = 'dashed', color = fuzzer_color[fuzzer], label=f'{fuzzer} - worst')
    pyplot.fill_between(x_axis, worst, best, color=fuzzer_color[fuzzer], alpha=0.1)
    pyplot.plot(x_axis, avg, color = fuzzer_color[fuzzer], label=f'{fuzzer} - avg')
  pyplot.legend()
  pyplot.savefig(plot_name)
  
  

if __name__ == "__main__":
  parser = argparse.ArgumentParser()
  parser.add_argument("-r", help="results dir to share the evaluation results ")
  parser.add_argument("-n", help="number of trial")

  args = parser.parse_args()
  for bench in benchmark_list:
    all_cov, fuzzer_cov_pair = plot_benchmark_n_trails('%s/%s' % (args.r, bench), int(args.n))
    write_plot_bench('fuzz-%s.png' % (bench), fuzzer_cov_pair)
    