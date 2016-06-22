#!/usr/bin/python3

import codecs
import subprocess
import sys
from collections import defaultdict

THRESHOLD = 2

if len(sys.argv) != 4:
    sys.stderr.write("Usage: %s translated untranslated ngram_len\n" % sys.argv[0])
    sys.exit(1)

ngram_len = int(sys.argv[3])

CMD='cat'
if subprocess.call('which pv > /dev/null', shell=True) == 0:
    CMD='pv -Wl'

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
def getPhrase(idvec):
    return str.join(' ', map(getWord, idvec))
def getIDVec(phrase):
    if type(phrase) == str:
        return tuple( map(getID, phrase.split()) )
    return tuple( map(getID, phrase) )

def covered_n(filename):
    coveredSet = set()
    p = subprocess.Popen("%s %s" % (CMD, filename), shell=True, stdout=subprocess.PIPE)
    if p:
        reader = codecs.getreader('utf-8')(p.stdout)
        for line in reader:
            idvec = getIDVec( line.strip() )
            for i in range(0, len(idvec)):
                for j in range(i+1, min(i+ngram_len+1,len(idvec)+1)):
                    coveredSet.add(idvec[i:j])
    return coveredSet

def uncovered_n(filename, coveredSet):
    cnts = defaultdict(int)
    p = subprocess.Popen("%s %s" % (CMD, filename), shell=True, stdout=subprocess.PIPE)
    if p:
        reader = codecs.getreader('utf-8')(p.stdout)
        for line in reader:
            idvec = getIDVec( line.strip() )
            for i in range(0, len(idvec)):
                for j in range(i+1, min(i+ngram_len+1,len(idvec)+1)):
                    if idvec[i:j] not in coveredSet:
                        cnts[ idvec[i:j] ] += 1
    return cnts

coveredSet = covered_n(sys.argv[1])
uncoveredCounter = uncovered_n(sys.argv[2], coveredSet)

for key in uncoveredCounter.keys():
    count = uncoveredCounter[key]
    if count >= THRESHOLD:
        print("%s\t%d" % (getPhrase(key),count))

