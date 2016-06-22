#!/usr/bin/python3

import sys
from collections import defaultdict

debugging = True
def dprint(msg):
    if debugging:
        print(msg)

def showProgress(msg, count, total):
    if debugging:
        if count == total or count % 100 == 0:
            ratio = (100.0 * count)/total
#            sys.stdout.write("\rProcessed %4.2f%% #Phrases: %d/%d, #Selected: %d" % (ratio,count,total,selected))
            sys.stdout.write("\r%s: %4.2f%% (%d / %d)" % (msg,ratio,count,total))

if len(sys.argv) != 6:
    print("Usage: %s phrase_files in_src in_trg out_src out_trg" % sys.argv[0], file=sys.stderr)
    sys.exit(1)

srcLines = []
trgLines = []
phrases = []
phrase2indices = {}
maxLen = 0

dprint("Loading: %s" % sys.argv[2])
with open(sys.argv[2], 'r') as fobj:
    for line in fobj:
        srcLines.append(line.strip())
#        srcLines.append(' ' + line.strip() + ' ')
dprint("Loading: %s" % sys.argv[3])
with open(sys.argv[3], 'r') as fobj:
    for line in fobj:
#        trgLines.append(' ' + line.strip() + ' ')
        trgLines.append(line.strip())
dprint("Loading: %s" % sys.argv[1])
with open(sys.argv[1], 'r') as fobj:
    for line in fobj:
        fields = line.strip().split("\t")
        if fields[0]:
            phrases.append(fields[0])
            phrase2indices[fields[0]] = []
            maxLen = max(maxLen, len(fields[0].split(' ')))
#        if len(phrases) == 100:
#            break

#dprint("Making Indices:")
for index, line in enumerate(srcLines):
    words = line.strip().split(' ')
    for n in range(1, maxLen+1):
        for start in range(0, len(words)+1-n):
            phrase = str.join(' ', words[start:start+n])
            if phrase in phrase2indices:
                phrase2indices[phrase].append(index)
    showProgress("Making Indices", index, len(srcLines))
#    if index == 100:
#        break
dprint("")

#def findPhrase(lines, phrase):
#    phrase = " " + phrase + " "
#    for i, line in enumerate(lines):
#        if line.find(phrase) >= 0:
#            return i
#    return -1
##    return None

selectedSrcLines = []
with open(sys.argv[4], 'w') as outSrc, open(sys.argv[5], 'w') as outTrg:
#    dprint("Selecting Sentences")
    total = len(phrases)
    while phrases:
#        showProgress(total - len(phrases), total, len(selectedSrcLines))
#        dprint("#Phrases: %d, #Selected: %d" % (len(phrases),len(selectedSrcLines)))
#        dprint("Selected: %s" % len(selectedSrcLines))
        phrase = phrases.pop(0)
        for index in phrase2indices[phrase]:
            if not srcLines[index]:
                phrase2indices[phrase] = []
        if len(phrase2indices[phrase]) > 0:
            index = phrase2indices[phrase][0]
            outSrc.write(srcLines[index] + "\n")
            outTrg.write(trgLines[index] + "\n")
            outSrc.flush()
            outTrg.flush()
            srcLines[index] = ""
            trgLines[index] = ""
        del phrase2indices[phrase]
        showProgress("Processing Phrases", total - len(phrases), total)
#        dprint("Phrase: %s" % phrase)
#        dprint("Phrase (%d): %s" % (len(phrases),phrase))
#        if findPhrase(selectedSrcLines, phrase) >= 0:
#            continue
#        found = findPhrase(srcLines, phrase)
#        if found >= 0:
#            srcSent = srcLines.pop(found)
#            trgSent = trgLines.pop(found)
#            outSrc.write(srcSent.strip() + "\n")
#            outTrg.write(trgSent.strip() + "\n")
#            selectedSrcLines.append(srcSent)
#            outSrc.flush()
#            outTrg.flush()
#            dprint("Found (%d/%d) Sentence: %s" % (found,len(srcLines),srcSent))
#            matchIndices = []
#            for i, _ in enumerate(phrases):
#                if srcSent.find(" " + phrases[i] + " ") >= 0:
#                    matchIndices.append(i)
#            matchIndices.reverse()
#            for i in matchIndices:
#                dprint("Found (%d/%d) Phrase: %s" % (i,len(phrases),phrases[i]))
#                phrases.pop(i)
    dprint("")

