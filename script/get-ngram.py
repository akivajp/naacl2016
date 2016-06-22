#!/usr/bin/python3

import sys
from collections import defaultdict

if len(sys.argv) != 4:
    print("Usage: %s corpus ngram_len outfile" % sys.argv[0], file=sys.stderr)
    sys.exit(1)

ngram_len = int(sys.argv[2])

def calc_n(filename):
    cnts = defaultdict(lambda: 0)
    with open(filename) as trans_file:
        for line in trans_file:
            words = line.strip().split(' ')
            for i in range(0, len(words)):
                for j in range(i+1, min(i+ngram_len+1,len(words)+1)):
                    cnts[" ".join(words[i:j])] += 1
    return cnts

print("Begin Count")
counts = calc_n(sys.argv[1])
print("End Count")

with open(sys.argv[3], 'w') as outFile:
    print("Begin Sort")
    items = sorted(counts.items(), key=lambda x: x[1], reverse=True)
    print("End Sort")
    for k,v in items:
#        print("%s\t%d" % (k,v))
        outFile.write("%s\t%d\n" % (k,v))

