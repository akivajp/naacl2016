#!/usr/bin/env python

import argparse
import json
import sys

def toStr(s):
    if str == bytes:
       # Python2
       if type(s) == unicode:
          return s.encode('utf-8')
       else:
          return str(s)
    else:
       # Python3
       if type(s) == bytes:
          return str(s, 'utf-8')
       else:
          return str(s)

def extract(args):
    phrase_count = 0
    word_count = 0
    total_duration = 0
    with open(args.json_file) as fobj:
        for line in fobj:
            if args.min_count > 0:
                if args.count == 'p':
                    if phrase_count >= args.min_count:
                        break
                if args.count == 'w':
                    if word_count >= args.min_count:
                        break
            try:
                data = json.loads( line )
                if float(data['confidence']) < float(args.threshold):
                    continue
                if data['trg_phrase']:
                    phrase_count += 1
                    word_count += len( data['src_phrase'].split(' ') )
                    src = toStr(data['src_phrase'])
                    trg = toStr(data['trg_phrase'])
                    total_duration += float( data['duration'] )
                    if args.output == 'b':
                        print("%s\t%s" % (src,trg))
                    if args.output == 's':
                        print(src)
                    if args.output == 't':
                        print(trg)
            except Exception as e:
                #print(e)
                pass
    if args.output == 'd':
        print(total_duration)

def main():
    parser = argparse.ArgumentParser(description = 'Extract translated (parallel) phrase pairs')
    parser.add_argument('--count', '-c', choices=('p','w'), default='p', help='p:Phrases, w:Words for element count')
    parser.add_argument('--threshold', '-t', choices=('1','2','3'), default='1', help='lower threshold of confidence level')
    parser.add_argument('--output', '-o', choices=('b','s','t','d'), default='b', help='b:Both (src tab trg), s:Source, t:Target, d:Duration (total)  for output')
    parser.add_argument('json_file')
    parser.add_argument('min_count', type=int, nargs='?', default=0)
    args = parser.parse_args()
    #print(args)
    extract(args)

if __name__ == '__main__':
    main()

