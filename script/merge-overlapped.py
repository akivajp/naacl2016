#!/usr/bin/python3

import sys
from collections import defaultdict

DISTANCE=100
FACTOR=2.0

debugging = True
def dprint(msg):
    if debugging:
        print(msg)

if len(sys.argv) != 4:
    print("Usage: %s in_phrases in_corpus out_phrases" % sys.argv[0], file=sys.stderr)
    sys.exit(1)

def findPhrase(lines, phrase):
    phrase = " " + phrase + " "
    for i, line in enumerate(lines):
        if line.find(phrase) >= 0:
            return i
    return -1

def merge(s1, s2):
    mergedSet = set()
    words1 = s1.split(" ")
    words2 = s2.split(" ")
    for i in range(0, len(words1)):
        prefix = str.join(" ", words1[i:None]) + " "
        if s2.find(prefix) == 0:
            right = str.join(" ", words2[len(words1)-i:None])
            if right:
              mergedSet.add(s1 + " " + right)
            else:
              mergedSet.add(s1)
    return mergedSet

pathPhrases = sys.argv[1]
pathCorpus  = sys.argv[2]
pathOut = sys.argv[3]

dprint("Loading: %s" % pathPhrases)
phrases = []
with open(pathPhrases) as fobj:
    for line in fobj:
        fields = line.strip().split("\t")
        if len(fields) == 2:
            phrase = fields[0]
            count = int(fields[1])
            phrases.append( [phrase, count] )

dprint("Loading: %s" % pathCorpus)
lines = []
with open(pathCorpus) as fobj:
    for line in fobj:
        lines.append(line.strip())

outFile = open(pathOut, "w")
while phrases:
    phrase, count = phrases.pop(0)
    i = 0
    dprint("Phrase: %s, Count: %s" % (phrase,count))
    while True:
        if i >= len(phrases):
            break
        phrase2, count2 = phrases[i]
        dprint("Candidate: %s Count: %s" % (phrase2,count2))
        if i >= DISTANCE and count2 < count / FACTOR:
            break
        if " " + phrase + " " in " " + phrase2 + " ":
            phrase = phrase2
            phrases.pop(i)
            i = 0
            dprint("Merged: %s" % phrase)
            continue
        elif " " + phrase2 + " " in " " + phrase + " ":
            phrases.pop(i)
            i = 0
            dprint("Merged: %s" % phrase)
            continue
        mergedSet = merge(phrase, phrase2)
        mergedSet.union( merge(phrase2, phrase) )
        matched = False
        if mergedSet:
            for merged in mergedSet:
                if findPhrase(lines, merged) >= 0:
                    phrase = merged
                    phrases.pop(i)
                    i = 0
                    dprint("Merged: %s" % phrase)
                    matched = True
                    break
        if not matched:
            i += 1
    outFile.write("%s\t%s\n" % (phrase,count) )
    dprint("")

