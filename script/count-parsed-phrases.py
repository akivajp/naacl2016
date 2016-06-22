#!/usr/bin/python3

import sys
from collections import defaultdict

THRESHOLD=2

debugging = True
def dprint(msg):
    if debugging:
        print(msg)

if len(sys.argv) != 1:
    sys.stderr.write("Usage: %s < parse_trees_file > struct_freq\n" % sys.argv[0])
    sys.exit(1)

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

def parse(expr, i = 0):
    cont = ''
    while i < len(expr):
        #dprint('Expr[%s]: %s' % (i, expr[i]))
        if expr[i] == '(':
            #dprint('Push')
            cont = []
            while i < len(expr):
                if expr[i] == ')':
                    #dprint("Closing: %s" % cont)
                    return cont, i + 1
                item, i = parse(expr, i + 1)
                if item:
                    #print("Appending: %s" % item)
                    cont.append(item)
            return cont, i
        elif expr[i] == ')':
            #dprint("Closing: " + cont)
            return cont, i
        elif expr[i] == ' ':
            #dprint('Elem: ' + cont)
            return cont, i
        else:
            cont += expr[i]
            i += 1
    return cont, i

def extractPhrase(tree):
    words = ()
    if type(tree) == list:
        for elem in tree[1:None]:
            words += extractPhrase(elem)
    else:
        words += (getID(tree),)
    return words

def countPhrases(tree, counter = defaultdict(int)):
    if type(tree) == list:
        if len(tree) >= 3:
            words = extractPhrase(tree)
            #print(words)
            counter[words] += 1
        for elem in tree[1:None]:
            countPhrases(elem, counter)
    else:
        #print(getIDVec(tree))
        counter[getIDVec(tree)] += 1

counter = defaultdict(int)
for line in sys.stdin:
    line = line.strip()
    tree, _ = parse(line)
    #print(tree)
    if tree:
        countPhrases(tree, counter)

for key in counter.keys():
    count = counter[key]
    if count >= THRESHOLD:
        print("%s\t%s" % (getPhrase(key),count))

