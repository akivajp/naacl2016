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

# sentences in random order
if [ ! -f ${WORKDIR}/DONE.sent-rand ]; then
  show_exec paste ${PREPROC}/${PREFIX_ADD}train.toklow.{$SRC,$TRG} \| pv -Wl \| nl \| shuf \| pv -Wl \> ${WORKDIR}/sent-rand.paste
  show_exec cut -f2 ${WORKDIR}/sent-rand.paste \| pv -Wl \> ${WORKDIR}/sent-rand.${SRC}
  show_exec cut -f3 ${WORKDIR}/sent-rand.paste \| pv -Wl \> ${WORKDIR}/sent-rand.${TRG}
  show_exec touch ${WORKDIR}/DONE.sent-rand
fi

