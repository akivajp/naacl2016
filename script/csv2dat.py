#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys

if len(sys.argv) < 2:
    sys.stderr.write("usage: %s input_files\n" % sys.argv[0])
    sys.exit(1)

LINESTOP=0
#LINESTOP=20

#data = []
data = {}

for path in sys.argv[1:]:
    with open(path, 'r') as fobj:
        lineCount = 0
        for line in fobj:
            try:
                line = line.strip()
                if line[0:1] == '#':
                    continue
                lineCount += 1
                fields = line.split(',')
                record = {}
                record.setdefault('duration', 0.0)
                for field in fields:
                    keyval = field.split("=")
                    if len(keyval) == 2:
                        key = keyval[0].strip().lower()
                        try:
                            record[key] = float(keyval[1].strip())
                        except:
                            record[key] = keyval[1].strip()
                if type(record['bleu']) == float:
    #                data.append(record)
                    data[record['lines']] = record
                if LINESTOP and lineCount >= LINESTOP:
                    break
            except Exception as e:
                sys.stderr.write("Error(str): %s\n" % str(e))
                sys.stderr.write("Error(repr): %s\n" % repr(e))
                sys.stderr.write("File: %s\n" % path)
                sys.stderr.write("Line: %s\n" % line)
                sys.exit(1)
#data.sort(key = lambda r:r['lines'])
#for record in data:
for lines, record in sorted( data.items() ):
#    print("%(lines)6s %(words)6s %(bleu)10s %(duration)10s" % record)
    print("%(lines)6d %(words)6d %(bleu)12f %(duration)12.3f" % record)

