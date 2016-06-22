#!/usr/bin/python3

import sys
from collections import defaultdict

debugging = True
def dprint(msg):
    if debugging:
        print(msg)

if len(sys.argv) != 2:
    sys.stderr.write("Usage: %s length < parse_trees_file > struct_freq\n" % sys.argv[0])
    sys.exit(1)

length = int(sys.argv[1])

for line in sys.stdin:
    fields = line.strip().split('\t')
    if len(fields) == 2:
        words = fields[0].split()
        if len(words) >= length:
            print(line.strip())

