#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
source "${dir}/common.sh"

if [[ $# != 4 ]]; then
    echo "Usage: $0 SRC TRG SIMDIR BASEDIR"
    exit 1
fi

TYPE=pbmt
WD=`pwd`
#SIMDIR=$WD/baseline-growth
#BASEDIR=$WD/incr-moses
SRC=$1
TRG=$2
SIMDIR=$3
BASEDIR=$4
#SRCTRG=${SRC}${TRG}
#ALIGNTYPE=giza

LMORDER=5
#LMNAME=$LMORDER

#ID=incr-$TYPE-$SRCTRG-$ALIGNTYPE-lm$LMORDER

if [[ "x$TYPE" == "xhiero" ]]; then
    HIEROOPT="-hierarchical -glue-grammar -max-phrase-length 5"
else
    HIEROOPT="-reordering msd-bidirectional-fe"
fi

#CORPUSDIR="$SIMDIR/${SRC}-${TRG}"

#show_exec mkdir -p $MODELDIR

LINES=0
#if [ -f $CORPUSDIR/added.${SRC} ]; then
if [ -f $SIMDIR/added.${SRC} ]; then
  LINES=$(wc -l $SIMDIR/added.${SRC} | cut -d ' ' -f 1)
fi
TRAINDIR=$BASEDIR/$LINES
LASTDIR=$BASEDIR/last
ALIGN=$BASEDIR/align.txt
MMSAPT=$BASEDIR/mmsapt
ALIGNDIR=$BASEDIR/giza

BASELINE=
if [ -d $LASTDIR ]; then
  BASELINE=$(echo -baseline-extract $LASTDIR/model/extract -baseline-corpus $SIMDIR/growing.prev -baseline-alignment $ALIGN)
fi

show_exec mkdir -p $TRAINDIR/corpus
if [ $LINES -eq '0' ]; then
  show_exec ${dir}/incr-train-gizapp.sh $SIMDIR/orig $SRC $TRG $ALIGNDIR
  show_exec $MOSES/scripts/training/train-model.perl -reordering distance -parallel -cores $THREADS -root-dir $TRAINDIR -corpus $SIMDIR/orig -f $SRC -e $TRG -lm 0:$LMORDER:$WD/lm/$LMORDER/${SRC}-${TRG}.${TRG}.blm:8 -alignment-file ${ALIGNDIR}/align -alignment txt -mmsapt '""' -phrase-translation-table $MMSAPT:11:6 -do-steps 9 ">>" ${BASEDIR}/log 2\> /dev/stdout
  show_exec cp $SIMDIR/orig.${SRC} $TRAINDIR/corpus/${SRC}
  show_exec cp $SIMDIR/orig.${TRG} $TRAINDIR/corpus/${TRG}
else
  show_exec ${dir}/incr-train-gizapp.sh $SIMDIR/new $SRC $TRG $ALIGNDIR
  show_exec $MOSES/scripts/training/train-model.perl -reordering distance -parallel -cores $THREADS -root-dir $TRAINDIR -corpus $SIMDIR/orig -f $SRC -e $TRG -lm 0:$LMORDER:$WD/lm/$LMORDER/${SRC}-${TRG}.${TRG}.blm:8 -alignment-file ${ALIGNDIR}/align -alignment txt -mmsapt '""' -phrase-translation-table $MMSAPT:11:6 -do-steps 9 $BASELINE ">>" ${BASEDIR}/log 2\> /dev/stdout
  show_exec cp $SIMDIR/new.${SRC} $TRAINDIR/corpus/${SRC}
  show_exec cp $SIMDIR/new.${TRG} $TRAINDIR/corpus/${TRG}
fi

if [ -d $LASTDIR ]; then
  show_exec rm $LASTDIR
fi
show_exec ln -s $(abspath $TRAINDIR) $LASTDIR

show_exec cat $ALIGNDIR/align.txt ">>" $ALIGN
show_exec cp $ALIGNDIR/align.txt $TRAINDIR/model

show_exec $MOSES/scripts/training/build-mmsapt.perl --alignment $ALIGN --corpus $SIMDIR/growing --f $SRC --e $TRG --DIR $MMSAPT

show_exec cat $TRAINDIR/model/moses.ini \| sed -e "'s!${TRAINDIR}!${LASTDIR}!g'" \> $BASEDIR/moses.ini

