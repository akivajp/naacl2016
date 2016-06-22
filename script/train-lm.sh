#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
source "${dir}/common.sh"

if [ ${#ARGS[@]} -ne 3 ]; then
  echo "usage: $0 lang_src lang_trg order" > /dev/stderr
  exit 1
fi

SRC=${ARGS[0]}
TRG=${ARGS[1]}
ORDER=${ARGS[2]}

train_kenlm() {
  local SRC=$1
  local TRG=$2
  local ORDER=$3
  CORPUS=""
  if [ -f ${PREPROC_DIR}/${SRC}-${TRG}/${PREFIX_BOTH}train.toklow.${TRG} ]; then
    CORPUS=${PREPROC_DIR}/${SRC}-${TRG}/${PREFIX_BOTH}train.toklow.${TRG}
  elif [ -f ${PREPROC_DIR}/${TRG}-${SRC}/${PREFIX_BOTH}train.toklow.${TRG} ]; then
    CORPUS=${PREPROC_DIR}/${TRG}-${SRC}/${PREFIX_BOTH}train.toklow.${TRG}
  else
    echo "corpus not exists: ${PREPROC_DIR}/${SRC}-${TRG}/${PREFIX_BOTH}train.toklow.${TRG}"
    exit 1
  fi
  if [ ! -f lm/${ORDER}/DONE.train.${SRC}-${TRG}.${TRG} ]; then
    show_exec mkdir -p lm/${ORDER}
    show_exec ${TRAVATAR}/src/kenlm/lm/lmplz -o ${ORDER} -S 50% -T /tmp \< ${CORPUS} \> lm/${ORDER}/${SRC}-${TRG}.${TRG}.arpa
    show_exec touch lm/${ORDER}/DONE.train.${SRC}-${TRG}.${TRG}
  fi
  if [ ! -f lm/${ORDER}/DONE.binarize.${SRC}-${TRG}.${TRG} ]; then
    show_exec ${TRAVATAR}/src/kenlm/lm/build_binary -i lm/${ORDER}/${SRC}-${TRG}.${TRG}.arpa lm/${ORDER}/${SRC}-${TRG}.${TRG}.blm
    show_exec touch lm/${ORDER}/DONE.binarize.${SRC}-${TRG}.${TRG}
  fi
}

train_kenlm $SRC $TRG $ORDER
train_kenlm $TRG $SRC $ORDER

