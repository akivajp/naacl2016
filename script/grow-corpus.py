#!/usr/bin/python3

import sys
from collections import defaultdict

if len(sys.argv) != 6:
    print("Usage: %s src_labeled trg_labeled src_unlabeled trg_unlabeled ngram_unlabeled" % sys.argv[0], file=sys.stderr)
    sys.exit(1)
srcLabeled = sys.argv[1]
trgLabeled = sys.argv[2]
srcUnlabeled = sys.argv[3]
trgUnlabeled = sys.argv[4]
pathNGram = sys.argv[5]

def findPhrase(filepath, phrase):
    phrase = ' ' + phrase + ' '
    with open(filepath) as srcFile:
        lineNum = 1
        for line in srcFile:
            line = ' ' + line.strip() + ' '
            found = line.find(phrase)
            if found >= 0:
                return lineNum
            lineNum += 1
        return -1

def removeFileLine(filepath, lineNum):
    removed = None
    lines = []
    with open(filepath, 'r') as inFile:
        for line in inFile:
            lines.append(line)
    with open(filepath, 'w') as outFile:
        i = 0
        for line in lines:
            i += 1
            if i == lineNum:
                removed = line
            else:
                outFile.write(line)
    return removed

def appendLine(filepath, line):
    with open(filepath, 'a') as outFile:
        outFile.write(line)

print("Loading ngram")
listNGram = []
with open(pathNGram) as fileNGram:
    for line in fileNGram:
        cols = line.strip().split("\t")
        if len(cols) == 2:
            listNGram.append(cols)
print("Loaded ngram")

lineNum = None
while listNGram:
    ngram = listNGram.pop(0)[0]
    found = findPhrase(srcLabeled, ngram)
    if found >= 0:
        print("Covered N-Gram: %s" % ngram)
        continue
    found = findPhrase(srcUnlabeled, ngram)
    if found >= 0:
        print("Selecting uncovered N-Gram: %s" % ngram)
        lineNum = found
        break

if lineNum:
    print("Update file: %s" % srcUnlabeled)
    lineSrc = removeFileLine(srcUnlabeled, lineNum)
    if lineSrc:
        print("Update file: %s" % srcLabeled)
        appendLine(srcLabeled, lineSrc)
    print("Update file: %s" % trgUnlabeled)
    lineTrg = removeFileLine(trgUnlabeled, lineNum)
    if lineTrg:
        print("Update file: %s" % trgLabeled)
        appendLine(trgLabeled, lineTrg)

print("Update file: %s" % pathNGram)
print("Selected Source Sentence: %s" % lineSrc)
with open(pathNGram, 'w') as fileNGram:
    lineSrc = ' ' + lineSrc.strip() + ' '
    for col in listNGram:
        if lineSrc.find(' ' + col[0] + ' ') >= 0:
            print("Skip N-Gram: %s" % col[0])
            pass
        else:
            fileNGram.write("%s\t%s\n" % (col[0], col[1]))
print("Updated files")

