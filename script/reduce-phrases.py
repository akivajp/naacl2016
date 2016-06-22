#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
from subprocess import call, Popen, PIPE

if len(sys.argv) != 1:
    sys.stderr.write("Usage: %s < phrase_freq > reduced_phrase_freq\n" % sys.argv[0])
    sys.exit(1)

PV=None
if call('which pv > /dev/null', shell=True) == 0:
    PV='pv'

debugging = True
def dprint(msg):
    if debugging:
        print(msg)

word2id = {}
id2word = []
def getWord(num):
    if 0 <= num and num < len(id2word):
        return id2word[num]
    return "-UNK-"
def getID(word):
    if word not in word2id:
        word2id[word] = len(id2word)
        id2word.append(word)
    return word2id[word]
def getPhraseStr(idvec):
    return str.join(' ', map(getWord, idvec))
def getIDVec(phrase):
    if type(phrase) == str:
        return tuple( map(getID, phrase.split()) )
    return tuple( map(getID, phrase) )

phraseCounts = {}
phraseList = []
for line in sys.stdin:
    fields = line.strip().split("\t")
    if len(fields) == 2:
        phrase = getIDVec(fields[0])
        count = int(fields[1])
        phraseCounts[phrase] = count
        phraseList.append(phrase)

pv = None
if PV:
    cmd = "%s -Wl -N \"Processing Phrases\" -s %s > /dev/null" % (PV,len(phraseList))
    pv = Popen(cmd, shell=True, stdin=PIPE)

for phrase in reversed(phraseList):
    if pv:
        pv.stdin.write("\n")
    if phrase not in phraseCounts:
        continue
    if len(phrase) >= 2:
        count = phraseCounts[phrase]
        for left in range(0, len(phrase)):
            for right in range(left+1, len(phrase)+1):
                if right - left >= len(phrase):
                    continue
                subPhrase = phrase[left:right]
                if subPhrase not in phraseCounts:
                    continue
                subCount = phraseCounts[subPhrase]
                if count * 2 > subCount:
                    del phraseCounts[subPhrase]
if pv:
    pv.stdin.close()

for phrase in phraseList:
    if phrase in phraseCounts:
        count = phraseCounts[phrase]
        print("%s\t%s" % (getPhraseStr(phrase),count))

