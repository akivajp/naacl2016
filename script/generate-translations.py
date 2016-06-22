#!/usr/bin/python3

import argparse
import codecs
import subprocess
import sys
from collections import defaultdict

import argparse

parser = argparse.ArgumentParser(description='Translate phrases (arg1)  if they are in phrase table (stdin)')
parser.add_argument('phrasePath', type=str, help='path to file including phrases')
parser.add_argument('--progress', '-p', action='store_true',
                    help = 'show progress bar (pv command should be installed')
args = parser.parse_args()
#if len(sys.argv) != 2:
#    print("Usage: %s ngrams < phrasetable" % sys.argv[0], file=sys.stderr)
#    sys.exit(1)

CMD='cat'
if args.progress and subprocess.call('which pv > /dev/null', shell=True) == 0:
    CMD='pv -Wl'

srctrg_list = []
src_map = {}

#sys.stderr.write("Loading: %s\n" % sys.argv[1])
sys.stderr.write("Loading: %s\n" % args.phrasePath)
#p = subprocess.Popen("%s %s" % (CMD, sys.argv[1]), shell=True, stdout=subprocess.PIPE)
p = subprocess.Popen("%s %s" % (CMD, args.phrasePath), shell=True, stdout=subprocess.PIPE)
#with open(sys.argv[1]) as ngram_file:
if p:
    ngram_file = codecs.getreader('utf-8')(p.stdout)
    for line in ngram_file:
        tup = line.strip().split("\t")
        if len(tup) != 2: continue
        k, v = tup
        src_map[k] = len(srctrg_list)
        srctrg_list.append( (k, "", -1.0e99, float(v)) )
    ngram_file.close()

sys.stderr.write("Loading StdIn\n")
p = subprocess.Popen("%s" % (CMD), shell=True, stdout=subprocess.PIPE)
if p:
    reader = codecs.getreader('utf-8')(p.stdout)
#    for line in sys.stdin:
    for line in reader:
        src, trg, score = line.strip().split("\t")
        score = float(score)
        if src in src_map:
            src_id = src_map[src]
            if srctrg_list[src_id][2] < score:
                srctrg_list[src_id] = (src, trg, score, srctrg_list[src_id][3])
    reader.close()

p = subprocess.Popen("%s" % (CMD), shell=True, stdin=subprocess.PIPE)
if p:
    writer = codecs.getwriter('utf-8')(p.stdin)
    for src, trg, score, select in srctrg_list:
        writer.write("%s\t%s\t%.4g\t%.4g\n" % (src, trg, score, select))
#        print("%s\t%s\t%.4g\t%.4g" % (src, trg, score, select))

