from __future__ import print_function
from collections import Counter
import sys
import re
import numpy as np

# This takes the precision, recall, and f1 metrics in out/summary.txt and prints
# summary statistics to stdout
#
# Input: filename of a summary.txt file as first command line argument
#
# Output: Table containing average pd, pf, f1, ROC performance of each model.
#         Each output row is the perf stats for the dataset specified by the 'dataset' column

def main(argv):
    data_file = open(argv[1])
    currentDataset = "unknownDataset"
    data = {}
    for line in data_file.readlines():
        # a line is either <datasetname> or <one whitespace character> or <numbers>
        # filter out everything but <numbers>
        if(len(line) > 1):
            if(re.match("[^a-zA-Z]", line) and len(line) > 1): # if line contains numbers
                stats = line.split(" ")
                current = data[currentDataset]
                current['prec'].append(float(stats[0]))
                current['pd'].append(float(stats[1]))
                current['pf'].append(float(stats[2]))
                current['f1'].append(float(stats[3]))
                current['roc'].append(float(stats[4]))
            elif("before" in line): # line is the dataset name
                currentDataset = line[:-1]
                # Initialize stats dictionary for current dataset
                data[currentDataset] = {'name': currentDataset, 'prec': [], 'pd': [], 'pf': [], 'f1': [], 'roc': []}
    averages = {}
    for dataset in data:
        averages[dataset] = {'name': dataset, 'prec': [], 'pd': [], 'pf': [], 'f1': [], 'roc': []}
        averages[dataset]['prec'] = "%.2f" % np.average(data[dataset]['prec'])
        averages[dataset]['pd'] = "%.2f" % np.average(data[dataset]['pd'])
        averages[dataset]['pf'] = "%.2f" % np.average(data[dataset]['pf'])
        averages[dataset]['f1'] = "%.2f" % np.average(data[dataset]['f1'])
        averages[dataset]['roc'] = "%.2f" % np.average(data[dataset]['roc'])
    print('dataset               | prec   pd     pf     F1     ROC')
    i = 0
    for stats in sorted(averages.items()):
        if(i%5 == 0):
            print('----------------------+--------------------------------')
        i += 1
        padding = ""
        for _ in range(21 - len(stats[0])):
            padding += ' '
        padding += '|'
        print(stats[0], padding, stats[1]['prec'], ' ', stats[1]['pd'], ' ', stats[1]['pf'], ' ', stats[1]['f1'], ' ', stats[1]['roc'])

if __name__ == '__main__':
	main(sys.argv)
