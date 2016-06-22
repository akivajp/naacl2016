#!/usr/bin/python

import codecs
#import subprocess
from subprocess import call, Popen, PIPE
import sys

debugging = True
def dprint(msg):
    if debugging:
        print(msg)

if len(sys.argv) != 3:
    sys.stderr.write("Usage: %s trasnslatedFreqFile untrasnslatedFreqFile\n" % sys.argv[0])
    sys.exit(1)

PV=None
if call('which pv > /dev/null', shell=True) == 0:
    PV='pv'

transFreqFile = sys.argv[1]
untransFreqFile = sys.argv[2]

pv = None
if PV:
    cmd = "%s -Wl -N \"Processing Phrases\" > /dev/null" % (PV,)
    pv = Popen(cmd, shell=True, stdin=PIPE)
with open(transFreqFile) as fobj:
    coveredSet = set()
    for line in fobj:
        if pv:
            pv.stdin.write("\n")
        fields = line.strip().split('\t')
        if len(fields) == 2:
            if int(fields[1]) >= 1:
                coveredSet.add(fields[0])
if pv:
    pv.stdin.close()

with open(untransFreqFile) as fobj:
    for line in fobj:
        fields = line.strip().split('\t')
        if len(fields) == 2:
            if int(fields[1]) >= 2:
                if fields[0] not in coveredSet:
                    sys.stdout.write(line)

