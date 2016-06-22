#!/usr/bin/python3

import sys

last_src, best_trg, best_score = None, None, -1e99
for line in sys.stdin:
    line = line.strip()
    if line[0] == '|': continue
    cols = line.split(" ||| ")
    feats = cols[2].split(" ")
    score = float(feats[2]) + 1e-4 * float(feats[3])
    if last_src != cols[0]:
        if last_src != None:
            print("%s\t%s\t%f" % (last_src, best_trg, best_score))
        best_score = -1e99
    if best_score < score:
        last_src, best_trg, best_score = cols[0], cols[1], score

print("%s\t%s\t%f" % (last_src, best_trg, best_score))
