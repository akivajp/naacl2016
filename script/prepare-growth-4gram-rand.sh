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

if [ ! -f src/count-phrases ]; then
  pushd src
  make
  popd
fi

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

# 4gram phrases in random order
if [ ! -f ${WORKDIR}/DONE.4gram-rand.${SRC} ]; then
  if [ -f ${WORKDIR}/4gram-freq.${SRC}-${TRG}.${TRG} ]; then
    show_exec paste ${WORKDIR}/4gram-freq.${SRC}-${TRG}.{$SRC,$TRG} \| grep -v "$'\t\t'" \| nl \| pv -Wl \| shuf \| pv -Wl \> ${WORKDIR}/4gram-rand.${SRC}-${TRG}.paste
    show_exec cat ${WORKDIR}/4gram-rand.${SRC}-${TRG}.paste \| cut -f2 \| pv -Wl \> ${WORKDIR}/4gram-rand.${SRC}-${TRG}.${SRC}
    show_exec cat ${WORKDIR}/4gram-rand.${SRC}-${TRG}.paste \| cut -f3 \| pv -Wl \> ${WORKDIR}/4gram-rand.${SRC}-${TRG}.${TRG}
    show_exec touch ${WORKDIR}/DONE.4gram-rand.${SRC}
  else
    echo "Translated 4gram-freq is not ready: ${WORKDIR}/4gram-freq.${SRC}-${TRG}.${TRG}" > /dev/stderr
    exit 1
  fi
fi

