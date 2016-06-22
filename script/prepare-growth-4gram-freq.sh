#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
source "${dir}/common.sh"

if [ ${#ARGS[@]} -lt 3 ]; then
  echo "usage: $0 src trg growthDir"
  exit 1
fi

SRC=$1
TRG=$2
WORKDIR=$3

if [ -d ${PREPROC_DIR}/${SRC}-${TRG} ]; then
  PREPROC=${PREPROC_DIR}/${SRC}-${TRG}
elif [ -d ${PREPROC_DIR}/${TRG}-${SRC} ]; then
  PREPROC=${PREPROC_DIR}/${TRG}-${SRC}
else
  echo "Directory noesn't exist: " ${PREPROC_DIR}/${SRC}-${TRG}
  exit 1
fi

if [ ! -d ${WORKDIR} ]; then
  show_exec mkdir -p ${WORKDIR}
fi

# Select n-grams to translate according to the baseline
if [ ! -f ${WORKDIR}/DONE.4gram-freq.${SRC} ]; then
  show_exec script/count-uncovered-ngram.py ${PREPROC}/${PREFIX_BASE}train.toklow.${SRC} ${PREPROC}/${PREFIX_ADD}train.toklow.${SRC} 4 \| pv -Wl \> ${WORKDIR}/4gram-uncovered.${SRC}
  show_exec cat ${WORKDIR}/4gram-uncovered.${SRC} \| pv -Wl \| sort -t "$'\t'" -k 2nr \| pv -Wl \> ${WORKDIR}/4gram-freq.${SRC}
  show_exec touch ${WORKDIR}/DONE.4gram-freq.${SRC}
fi

# get their translations using moses trained with base+additional corpus
if [ ! -f ${WORKDIR}/DONE.4gram-freq.trans-${SRC} ]; then
  INIFILE=moses-model/pbmt-${SRC}${TRG}-giza-${PREFIX_BOTH}train-lm5/model/moses.ini
  if [ -f "${INIFILE}" ]; then
    show_exec cat ${WORKDIR}/4gram-freq.${SRC} \| pv -Wl \| cut -f1 \> ${WORKDIR}/4gram-freq.${SRC}-${TRG}.${SRC}
    show_exec cat ${WORKDIR}/4gram-freq.${SRC} \| cut -f1 \| ${MOSES}/bin/moses -f ${INIFILE} -output-hypo-score -threads ${THREADS} "2>" ${WORKDIR}/log-4gram-freq.trans-${SRC} \| pv -Wl \| tee ">(cut -d ' ' -f2- > ${WORKDIR}/4gram-freq.${SRC}-${TRG}.${TRG})" \| cut -d "' '" -f1 \> ${WORKDIR}/4gram-freq.${SRC}-${TRG}.score
    show_exec touch ${WORKDIR}/DONE.4gram-freq.trans-${SRC}
  else
    echo "Moses translation model is not ready: $INIFILE" > /dev/stderr
    exit 1
  fi
fi

## get their translations from the one-best table
#if [ ! -f ${WORKDIR}/DONE.4gram-freq.trans-${SRC} ]; then
#  MODEL=moses-model/pbmt-${SRC}${TRG}-giza-${PREFIX_BOTH}train-lm5/model
#  if [ -f "${MODEL}/moses.ini" ]; then
#    if [ ! -f ${MODEL}/onebest-table.gz ]; then
#      show_exec zcat ${MODEL}/phrase-table.gz \| script/convert-moses-table.py \| pv -Wl \| gzip \> ${MODEL}/onebest-table.gz
#    fi
#    show_exec zcat ${MODEL}/onebest-table.gz \| script/generate-translations.py ${WORKDIR}/4gram-freq.${SRC} -p \> ${WORKDIR}/4gram-freq.${SRC}-${TRG}.trans
#    show_exec cat ${WORKDIR}/4gram-freq.${SRC}-${TRG}.trans \| grep -v "$'\t\t'" \| cut -f1 \| pv -Wl \> ${WORKDIR}/4gram-freq.${SRC}-${TRG}.${SRC}
#    show_exec cat ${WORKDIR}/4gram-freq.${SRC}-${TRG}.trans \| grep -v "$'\t\t'" \| cut -f2 \| pv -Wl \> ${WORKDIR}/4gram-freq.${SRC}-${TRG}.${TRG}
#    show_exec touch ${WORKDIR}/DONE.4gram-freq.trans-${SRC}
#  else
#    echo "Moses translation model is not ready: $MODEL/moses.ini" > /dev/stderr
#    exit 1
#  fi
#fi

