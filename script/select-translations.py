#!/usr/bin/python
# -*- coding: utf-8 -*-

import argparse
import sys
from subprocess import call, Popen, PIPE

def selectTranslations(args):
    fileInSrc = open(args.inSrcTrans, 'r')
    fileInTrg = open(args.inTrgTrans, 'r')
    fileInPhrases = open(args.inPhrases, 'r')
    fileOutSrc = open(args.outSrcTrans, 'w')
    fileOutTrg = open(args.outTrgTrans, 'w')
    pv = None
    if args.progress:
        if call('which pv > /dev/null', shell=True) == 0:
            pv = Popen('pv -Wl -N Output > /dev/null', shell=True, stdin=PIPE)
    for line in fileInPhrases:
        phrase = line.strip().split('\t')[0]
        while True:
            src = fileInSrc.readline().strip()
            trg = fileInTrg.readline().strip()
            if not (src and trg):
                break
            if phrase == src:
                fileOutSrc.write(src + "\n")
                fileOutTrg.write(trg + "\n")
                if pv:
                    pv.stdin.write("\n")
                break

def main():
    parser = argparse.ArgumentParser(description = 'Select translations of given phrases with translated phrase pairs')
    parser.add_argument('inSrcTrans', help='File including phrases in source language')
    parser.add_argument('inTrgTrans', help='File including translated phrases in target language')
    parser.add_argument('inPhrases', help='File including phrases to translate')
    parser.add_argument('outSrcTrans', help='Output file for source phrases')
    parser.add_argument('outTrgTrans', help='Outpuf file for target phrases')
    parser.add_argument('--progress', '-p', action='store_true', help='Show progress bar')
    args = parser.parse_args()
    selectTranslations(args)

if __name__ == '__main__':
    main()

