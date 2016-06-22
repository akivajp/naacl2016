#!/bin/bash

BIN=$HOME/usr/local/bin

KYTEA=$HOME/usr/local/kytea
#KYTEA_ZH_DIC=$HOME/usr/local/share/kytea/lcmc-0.4.0-1.mod

GIZAPP=$HOME/usr/local/giza-pp
INCGIZAPP=$HOME/usr/local/inc-giza-pp
TRAVATAR=$HOME/usr/local/travatar

CKYLARK=$HOME/usr/local/Ckylark
MOSES=$HOME/usr/local/mosesdecoder
TRAVATAR=$HOME/usr/local/travatar
SRILM=$HOME/usr/local/srilm/bin/i686-m64
BIN=$HOME/usr/local/bin

TEST_SIZE=1500
DEV_SIZE=1500

ORDER=5
THREADS=8
CLEAN_LENGTH=60
NPROC=$(nproc 2> /dev/null || echo $THREADS)

#CORPUS1_TRAIN=ja-en/preproc/rtrain/low
#CORPUS1_TEST=ja-en/preproc/rtest/low
#CORPUS1_DEV=ja-en/preproc/rdev/low
#CORPUS2_TRAIN=ja-en/preproc/ktrain/low
#CORPUS2_TEST=ja-en/preproc/ktest/low
#CORPUS2_DEV=ja-en/preproc/kdev/low

# The location of the corpora
CORPUS_DIR=./corpora/data
PREPROC_DIR=./corpora/preproc

PREFIX_BASE=base-
PREFIX_ADD=add-
PREFIX_BOTH=both-

