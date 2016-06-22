#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
source "${dir}/common.sh"

if [ $# -lt 3 ]; then
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

# Select phrases from parse treed
if [ ! -f ${WORKDIR}/DONE.reduced-maxsubst-freq.${SRC} ]; then
  if [ -f ${WORKDIR}/maxsubst-freq.${SRC} ]; then
    show_exec cat ${WORKDIR}/maxsubst-freq.${SRC} \| pv -Wl \| ${dir}/reduce-phrases.py \| pv -Wl \> ${WORKDIR}/reduced-maxsubst-freq.${SRC}
    show_exec touch ${WORKDIR}/DONE.reduced-maxsubst-freq.${SRC}
  else
    echo "Phrase counts file is not available: ${WORKDIR}/maxsubst-freq.${SRC}" > /dev/stderr
    exit 1
  fi
fi

# get their translations using translated phrases files
if [ ! -f ${WORKDIR}/DONE.reduced-maxsubst-freq.trans-${SRC} ]; then
  if [ -f ${WORKDIR}/maxsubst-freq.${SRC}-${TRG}.${TRG} ]; then
    show_exec ${dir}/select-translations.py ${WORKDIR}/maxsubst-freq.${SRC}-${TRG}.{$SRC,$TRG} ${WORKDIR}/reduced-maxsubst-freq.${SRC} ${WORKDIR}/reduced-maxsubst-freq.${SRC}-${TRG}.{$SRC,$TRG} -p
    show_exec touch ${WORKDIR}/DONE.reduced-maxsubst-freq.trans-${SRC}
  else
    echo "Translated phrases file is not available: ${WORKDIR}/maxsubst-freq.${SRC}-${TRG}.${TRG}" > /dev/stderr
    exit 1
  fi
fi

