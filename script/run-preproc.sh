#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
source "${dir}/common.sh"

if [ ${#ARGS[@]} -ne 2 ]; then
  echo "usage: lang_src lang_trg"
  exit 1
fi

SRC=$1
TRG=$2
if [[ $TRG == en ]]; then
  TRG=$SRC
  SRC=en
elif [[ $SRC > $TRG ]]; then
  TMP=$SRC
  SRC=$TRG
  TRG=$TMP
fi

get_range() {
  if [ $# -eq 4 ]; then
    local INFILE=$1
    let FROM=$2
    let SIZE=$3
    local OUTFILE=$4
    show_exec cat ${INFILE} \| tail -n +${FROM} \| head -n ${SIZE} \> ${OUTFILE}
  elif [ $# -eq 3 ]; then
    local INFILE=$1
    let FROM=$2
    local OUTFILE=$3
    show_exec cat ${INFILE} \| tail -n +${FROM} \> ${OUTFILE}
  fi
}

uniq_shuffle() {
  CORPUS=$1
  SRC=$2
  TRG=$3
  NAME=$4
  PAIR="${SRC}-${TRG}"
  show_exec paste ${CORPUS}.${SRC} ${CORPUS}.${TRG} \| pv -Wl \| sort \| uniq \| pv -Wl \> ${CORPUS_DIR}/${NAME}.${PAIR}.paste.uniq
  show_exec cat ${CORPUS_DIR}/${NAME}.${PAIR}.paste.uniq \| nl \| pv -Wl \| sort -R \| pv -Wl \> ${CORPUS_DIR}/${NAME}.${PAIR}.paste.rand
  show_exec cut -f2 ${CORPUS_DIR}/${NAME}.${PAIR}.paste.rand \| pv -Wl \> ${CORPUS_DIR}/${NAME}.${PAIR}.${SRC}
  show_exec cut -f3 ${CORPUS_DIR}/${NAME}.${PAIR}.paste.rand \| pv -Wl \> ${CORPUS_DIR}/${NAME}.${PAIR}.${TRG}
}

divide_corpus() {
  SRC=$1
  TRG=$2
  PAIR="${SRC}-${TRG}"
  WCORPUS=$(get_corpus_wmt $SRC $TRG)
  uniq_shuffle ${WCORPUS} ${SRC} ${TRG} wrand
#  get_range ${WCORPUS}.${SRC} 1 ${TEST_SIZE} ${CORPUS_DIR}/wtest.${PAIR}.${SRC}
#  get_range ${WCORPUS}.${TRG} 1 ${TEST_SIZE} ${CORPUS_DIR}/wtest.${PAIR}.${TRG}
#  get_range ${WCORPUS}.${SRC} 1+${TEST_SIZE} ${DEV_SIZE} ${CORPUS_DIR}/wdev.${PAIR}.${SRC}
#  get_range ${WCORPUS}.${TRG} 1+${TEST_SIZE} ${DEV_SIZE} ${CORPUS_DIR}/wdev.${PAIR}.${TRG}
#  get_range ${WCORPUS}.${SRC} 1+${TEST_SIZE}+${DEV_SIZE} ${CORPUS_DIR}/wtrain.${PAIR}.${SRC}
#  get_range ${WCORPUS}.${TRG} 1+${TEST_SIZE}+${DEV_SIZE} ${CORPUS_DIR}/wtrain.${PAIR}.${TRG}
  ECORPUS=$(get_corpus_emea $SRC $TRG)
  get_range ${ECORPUS}.${SRC} 1 ${TEST_SIZE} ${CORPUS_DIR}/etest.${PAIR}.${SRC}
  get_range ${ECORPUS}.${TRG} 1 ${TEST_SIZE} ${CORPUS_DIR}/etest.${PAIR}.${TRG}
  get_range ${ECORPUS}.${SRC} 1+${TEST_SIZE} ${DEV_SIZE} ${CORPUS_DIR}/edev.${PAIR}.${SRC}
  get_range ${ECORPUS}.${TRG} 1+${TEST_SIZE} ${DEV_SIZE} ${CORPUS_DIR}/edev.${PAIR}.${TRG}
  get_range ${ECORPUS}.${SRC} 1+${TEST_SIZE}+${DEV_SIZE} ${CORPUS_DIR}/etrain.${PAIR}.${SRC}
  get_range ${ECORPUS}.${TRG} 1+${TEST_SIZE}+${DEV_SIZE} ${CORPUS_DIR}/etrain.${PAIR}.${TRG}

  show_exec cat ${CORPUS_DIR}/{w,e}train.${PAIR}.${SRC} \> ${CORPUS_DIR}/wetrain.${PAIR}.${SRC}
  show_exec cat ${CORPUS_DIR}/{w,e}train.${PAIR}.${TRG} \> ${CORPUS_DIR}/wetrain.${PAIR}.${TRG}
}

preproc_by_name() {
  SRC=$1
  TRG=$2
  NAME=$3
  PAIR="${SRC}-${TRG}"
  WORKDIR=${PREPROC_DIR}/${PAIR}
  if [ ! -f ${WORKDIR}/DONE.preproc.${NAME} ]; then
    for lang in ${SRC} ${TRG}; do
      show_exec mkdir -p ${WORKDIR}
      case $lang in
        ja) show_exec cat ${CORPUS_DIR}/${NAME}.${PAIR}.${lang} \| ${KYTEA}/src/bin/kytea -notags \| sed -e "'s/|/ -BAR- /g'" \| pv -Wl \> ${WORKDIR}/${NAME}.tok.${lang};;
        *) show_exec ${TRAVATAR}/src/bin/tokenizer \< ${CORPUS_DIR}/${NAME}.${PAIR}.${lang} \| sed -e "'s/|/ -BAR- /g'" \| pv -Wl \> ${WORKDIR}/${NAME}.tok.${lang};;
      esac
    done
    if [[ "${NAME}" =~ "train" ]]; then
      show_exec ${TRAVATAR}/script/train/clean-corpus.pl -max_len ${CLEAN_LENGTH} ${WORKDIR}/${NAME}.tok.{$SRC,$TRG} ${WORKDIR}/${NAME}.clean.{$SRC,$TRG}
      show_exec ${TRAVATAR}/script/tree/lowercase.pl \< ${WORKDIR}/${NAME}.clean.${SRC} \| pv -Wl \> ${WORKDIR}/${NAME}.toklow.${SRC}
      show_exec ${TRAVATAR}/script/tree/lowercase.pl \< ${WORKDIR}/${NAME}.clean.${TRG} \| pv -Wl \> ${WORKDIR}/${NAME}.toklow.${TRG}
    else
      show_exec ${TRAVATAR}/script/tree/lowercase.pl \< ${WORKDIR}/${NAME}.tok.${SRC} \| pv -Wl \> ${WORKDIR}/${NAME}.toklow.${SRC}
      show_exec ${TRAVATAR}/script/tree/lowercase.pl \< ${WORKDIR}/${NAME}.tok.${TRG} \| pv -Wl \> ${WORKDIR}/${NAME}.toklow.${TRG}
    fi
    touch ${WORKDIR}/DONE.preproc.${NAME}
  fi
}

parse() {
  local SRC=$1
  local TRG=$2
  local NAME=$3
  local WORKDIR=${PREPROC_DIR}/${SRC}-${TRG}
  if [ ! -f ${WORKDIR}/DONE.parse.${NAME} ]; then
    for lang in $SRC $TRG; do
      case ${lang} in
        en|ja)
          if [ ! -f ${WORKDIR}/DONE.parse.${NAME}.clean.${lang} ]; then
            show_exec ${dir}/parallel-parse.sh ${lang} ${WORKDIR}/${NAME}.clean.${lang} ${WORKDIR}/${NAME}.tree.${lang} --splitsize=10000 --threads=${THREADS}
            show_exec rm -rf ${WORKDIR}/tmp
          fi
          show_exec cat ${WORKDIR}/${NAME}.tree.${lang} \| ${TRAVATAR}/script/tree/lowercase.pl \| pv -Wl \> ${WORKDIR}/${NAME}.treelow.${lang}
          ;;
        *)
          show_exec echo "language not supported for parsing: ${lang}"
          ;;
      esac
    done
    touch ${WORKDIR}/DONE.parse.${NAME}
  fi
}

merge_corpus() {
  SRC=$1
  TRG=$2
  BASE=$3
  ADD=$4
  BOTH=$5
  WORKDIR=${PREPROC_DIR}/${SRC}-${TRG}
  for lang in $SRC $TRG; do
    for type in toklow tree; do
      if [ ! -f ${WORKDIR}/DONE.merge.${BOTH}.${type}.${lang} ]; then
        if [ -f ${WORKDIR}/${BASE}.${type}.${lang} -a -f ${WORKDIR}/${ADD}.${type}.${lang} ]; then
          show_exec cat ${WORKDIR}/${BASE}.${type}.${lang} ${WORKDIR}/${ADD}.${type}.${lang} \| pv -l \> ${WORKDIR}/${BOTH}.${type}.${lang}
          show_exec touch ${WORKDIR}/DONE.merge.${BOTH}.${type}.${lang}
        fi
      fi
    done
  done
}

preproc_corpus() {
  SRC=$1
  TRG=$2
  WORKDIR=${PREPROC_DIR}/${SRC}-${TRG}
  local LOG=$PWD/log/preproc-${SRC}-${TRG}
#  divide_corpus $SRC $TRG
  for prefix in ${PREFIX_BASE} ${PREFIX_ADD}; do
    preproc_by_name ${SRC} ${TRG} ${prefix}test
    preproc_by_name ${SRC} ${TRG} ${prefix}dev
    preproc_by_name ${SRC} ${TRG} ${prefix}train
  done
  merge_corpus ${SRC} ${TRG} ${PREFIX_BASE}test  ${PREFIX_ADD}test  ${PREFIX_BOTH}test
  merge_corpus ${SRC} ${TRG} ${PREFIX_BASE}dev   ${PREFIX_ADD}dev   ${PREFIX_BOTH}dev
  merge_corpus ${SRC} ${TRG} ${PREFIX_BASE}train ${PREFIX_ADD}train ${PREFIX_BOTH}train
#  for prefix in ${PREFIX_BASE} ${PREFIX_ADD}; do
#    parse ${SRC} ${TRG} ${prefix}train
#  done
  parse ${SRC} ${TRG} ${PREFIX_ADD}train
  touch ${PREPROC_DIR}/${SRC}-${TRG}/DONE.preproc
}

preproc_corpus $SRC $TRG

