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
if [ ! -f ${WORKDIR}/DONE.reduced-struct-noleaf-freq.${SRC} ]; then
  if [ -f ${WORKDIR}/reduced-struct-freq.${SRC} ]; then
    show_exec cat ${WORKDIR}/reduced-struct-freq.${SRC} \| ${dir}/prune-by-length.py 2 \| pv -Wl \> ${WORKDIR}/reduced-noleaf-struct-freq.${SRC}
    show_exec touch ${WORKDIR}/DONE.reduced-noleaf-struct-freq.${SRC}
  else
    echo "Phrase counts file is not available: ${WORKDIR}/reduced-struct-freq.${SRC}" > /dev/stderr
    exit 1
  fi
fi

# get their translations using translated phrases files
if [ ! -f ${WORKDIR}/DONE.reduced-noleaf-struct-freq.trans-${SRC} ]; then
  if [ -f ${WORKDIR}/reduced-struct-freq.${SRC}-${TRG}.${TRG} ]; then
    show_exec ${dir}/select-translations.py ${WORKDIR}/struct-freq.${SRC}-${TRG}.{$SRC,$TRG} ${WORKDIR}/reduced-noleaf-struct-freq.${SRC} ${WORKDIR}/reduced-noleaf-struct-freq.${SRC}-${TRG}.{$SRC,$TRG} -p
    show_exec touch ${WORKDIR}/DONE.reduced-noleaf-struct-freq.trans-${SRC}
  else
    echo "Translated phrases file is not available: ${WORKDIR}/reduced-struct-freq.${SRC}-${TRG}.${TRG}" > /dev/stderr
    exit 1
  fi
fi

