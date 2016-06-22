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

# Select sentences including 4gram phrases in frequent order
if [ ! -f ${WORKDIR}/DONE.sent-by-4gram-freq.${SRC} ]; then
  if [ -f ${WORKDIR}/4gram-freq.${SRC} ]; then
    show_exec script/select-sentences.py ${WORKDIR}/4gram-freq.${SRC} ${PREPROC}/${PREFIX_ADD}train.toklow.{$SRC,$TRG} ${WORKDIR}/sent-by-4gram-freq.${SRC}-${TRG}.{$SRC,$TRG}
    show_exec touch ${WORKDIR}/DONE.sent-by-4gram-freq.${SRC}
  else
    echo "4gram frequency file is not ready: ${WORKDIR}/4gram-freq.${SRC}" > /dev/stderr
    exit 1
  fi
fi

