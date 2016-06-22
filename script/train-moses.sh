#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
source "${dir}/common.sh"

if [[ ${#ARGS[@]} != 3 ]]; then
    echo "Usage: $0 SRC TRG DATA_TYPE"
    exit 1
fi

TYPE=pbmt
WD=`pwd`
SRC=$1
TRG=$2
SRCTYPE=low
TRGTYPE=low
#if [[ $SRC == "ja" ]]; then 
#    F=$SRC; E=$TRG
#else 
#    F=$TRG; E=$SRC
#fi
#FE="$F-$E"
if [[ $SRC == "en" ]]; then
  PAIR="en-${TRG}"
else
  PAIR="en-${SRC}"
fi
SRCTRG=${SRC}${TRG}
ALIGNTYPE=giza

DTYPE=$3
DNAME=preproc/$DTYPE
LMORDER=5
LMNAME=$LMORDER

ID=$TYPE-$SRCTRG-$ALIGNTYPE-$DTYPE-lm$LMNAME


show_exec mkdir -p log
#[[ -e moses-model ]] || mkdir moses-model
show_exec mkdir -p moses-model

if [[ ! -f moses-model/$ID/model/moses.ini ]]; then
    if [[ "x$TYPE" == "xhiero" ]]; then
        HIEROOPT="-hierarchical -glue-grammar -max-phrase-length 5"
    else
#        HIEROOPT="-reordering msd-bidirectional-fe"
        HIEROOPT="-reordering distance"
    fi

#    mkdir moses-model/$ID
#    mkdir moses-model/$ID/model
#    show_exec mkdir -p moses-model/$ID/model
#    TRAINDIR="$WD/$FE/$DNAME/$SRC${SRCTYPE}-$TRG${TRGTYPE}-nobar"
#    mkdir -p $TRAINDIR
#    [[ -e $TRAINDIR/txt.$SRC ]] || sed 's/|/_BAR_/g' < $WD/$FE/$DNAME/${SRCTYPE}/$SRC > $TRAINDIR/txt.$SRC
#    [[ -e $TRAINDIR/txt.$TRG ]] || sed 's/|/_BAR_/g' < $WD/$FE/$DNAME/${TRGTYPE}/$TRG > $TRAINDIR/txt.$TRG

#    ALIGNSTR=
#    if [[ "x$ALIGNTYPE" != "xnone" ]]; then
#        [[ -e $WD/$FE/$DNAME/$ALIGNTYPE/txt.$SRC$TRG ]] || ln -s $WD/$FE/$DNAME/$ALIGNTYPE/$SRC$TRG $WD/$FE/$DNAME/$ALIGNTYPE/txt.$SRC$TRG
#        [[ -e $WD/$FE/$DNAME/$ALIGNTYPE/txt.$TRG$SRC ]] || ln -s $WD/$FE/$DNAME/$ALIGNTYPE/$TRG$SRC $WD/$FE/$DNAME/$ALIGNTYPE/txt.$TRG$SRC
#        ALIGNSTR="-alignment-file $WD/$FE/$DNAME/$ALIGNTYPE/txt -alignment $SRCTRG -first-step 4"
#    fi

#    echo "$MOSESDIR/scripts/training/train-model.perl $HIEROOPT -parallel -external-bin-dir $HOME/usr/local/giza-pp -root-dir moses-model/$ID -corpus $TRAINDIR/txt -f $SRC -e $TRG -lm 0:$LMORDER:$WD/lm/model/$LMNAME/$TRG.blm:8 $ALIGNSTR >& log/mosestrain-$ID.log"
#    $MOSESDIR/scripts/training/train-model.perl $HIEROOPT -parallel -external-bin-dir $HOME/usr/local/giza-pp -root-dir moses-model/$ID -corpus $TRAINDIR/txt -f $SRC -e $TRG -lm 0:$LMORDER:$WD/lm/model/$LMNAME/$TRG.blm:8 $ALIGNSTR >& log/mosestrain-$ID.log
    show_exec ${MOSES}/scripts/training/train-model.perl $HIEROOPT -parallel -cores ${THREADS} -external-bin-dir ${GIZAPP} -root-dir moses-model/${ID} -corpus corpora/preproc/${PAIR}/${DTYPE}.toklow -f $SRC -e $TRG -lm 0:${ORDER}:${PWD}/lm/${ORDER}/${SRC}-${TRG}.${TRG}.blm:8 "|&" tee log/mosestrain-$ID.log
fi

#echo moses-model/$ID/model/moses.ini
if [[ -f moses-model/$ID/model/moses.ini ]]; then
#    for g in rdev rtest kdev ktest; do
#        if [[ ! -e $WD/moses-model/$ID/filtered-$g ]]; then
#            if [[ "x$TYPE" == "xhiero" ]]; then
#                HIER=-hierarchical
#            else
#                HIER=
#            fi
#            mkdir -p $WD/$FE/preproc/$g/${TRGTYPE}nobar
#            mkdir -p $WD/$FE/preproc/$g/${SRCTYPE}nobar
#            [[ -e $WD/$FE/preproc/$g/${SRCTYPE}nobar/$SRC ]] || sed 's/|/_BAR_/g' < $WD/$FE/preproc/$g/${SRCTYPE}/$SRC > $WD/$FE/preproc/$g/${SRCTYPE}nobar/$SRC
#            [[ -e $WD/$FE/preproc/$g/${TRGTYPE}nobar/$TRG ]] || sed 's/|/_BAR_/g' < $WD/$FE/preproc/$g/${TRGTYPE}/$TRG > $WD/$FE/preproc/$g/${TRGTYPE}nobar/$TRG
##            echo "$HOME/work/mosesdecoder/scripts/training/filter-model-given-input.pl $HIER $WD/moses-model/$ID/filtered-$g moses-model/$ID/model/moses.ini $WD/$FE/preproc/$g/${SRCTYPE}nobar/$SRC &> log/filter-$ID-$g.log &"
#            echo "$MOSESDIR/scripts/training/filter-model-given-input.pl $HIER $WD/moses-model/$ID/filtered-$g moses-model/$ID/model/moses.ini $WD/$FE/preproc/$g/${SRCTYPE}nobar/$SRC &> log/filter-$ID-$g.log &"
##            nohup $HOME/work/mosesdecoder/scripts/training/filter-model-given-input.pl $HIER $WD/moses-model/$ID/filtered-$g moses-model/$ID/model/moses.ini $WD/$FE/preproc/$g/${SRCTYPE}nobar/$SRC &> log/filter-$ID-$g.log &
#            nohup $MOSESDIR/scripts/training/filter-model-given-input.pl $HIER $WD/moses-model/$ID/filtered-$g moses-model/$ID/model/moses.ini $WD/$FE/preproc/$g/${SRCTYPE}nobar/$SRC &> log/filter-$ID-$g.log &
#        fi
#    done

  for dtype in ${PREFIX_BASE}dev ${PREFIX_BASE}test ${PREFIX_ADD}dev ${PREFIX_ADD}test; do
    if [ ! -f moses-model/${ID}/filtered-${dtype}/moses.ini ]; then
      show_exec ${MOSES}/scripts/training/filter-model-given-input.pl ${PWD}/moses-model/${ID}/filtered-${dtype} moses-model/${ID}/model/moses.ini ${PWD}/corpora/preproc/${PAIR}/${dtype}.toklow.${SRC} "|&" tee log/filter-${ID}-${dtype}.log
    fi
  done
fi

