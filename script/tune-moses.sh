#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
source "${dir}/common.sh"

if [[ ${#ARGS[@]} != 3 ]]; then
    echo "Usage: $0 SRC TRG DATA_TYPE"
    exit 1
fi

SRC=${ARGS[0]}
TRG=${ARGS[1]}
DTYPE=${ARGS[2]}
PAIR=$(get_pair $SRC $TRG)

if [ ! -d "moses-tune" ]; then
  show_exec mkdir moses-tune
fi
if [ ! -d "moses-test" ]; then
  show_exec mkdir moses-test
fi

for prefix in ${PREFIX_BASE} ${PREFIX_ADD}; do
  INIFILE=moses-model/pbmt-${SRC}${TRG}-giza-${DTYPE}-lm5/filtered-${prefix}dev/moses.ini
  if [ ! -f moses-tune/${SRC}-${TRG}/${prefix}tune/moses.ini ]; then
    if [ -f ${INIFILE} ]; then
      show_exec ${MOSES}/scripts/training/mert-moses.pl $(abspath ${PREPROC_DIR}/${PAIR}/${prefix}dev.toklow.{$SRC,$TRG}) ${MOSES}/bin/moses ${INIFILE} --threads ${THREADS} --mertdir ${MOSES}/bin/ --working-dir ${PWD}/moses-tune/${SRC}-${TRG}/${prefix}tune --no-filter-phrase-table "|&" tee log/mertmoses-${prefix}.log
    else
      echo "Moses ini file has not been prepared: ${INIFILE}" > /dev/stderr
      exit 1
    fi
  fi
done

for prefix in ${PREFIX_BASE} ${PREFIX_ADD}; do
  show_exec mkdir -p moses-test/${SRC}-${TRG}/${prefix}test
  show_exec cat moses-tune/${SRC}-${TRG}/${prefix}tune/moses.ini \| sed -e "'s/dev/test/g'" \> moses-test/${SRC}-${TRG}/${prefix}test/moses.ini
  show_exec ${MOSES}/bin/moses -f moses-test/${SRC}-${TRG}/${prefix}test/moses.ini -threads ${THREADS} -n-best-list moses-test/${SRC}-${TRG}/${prefix}test/nbest.${TRG} -i ${PREPROC_DIR}/${PAIR}/${prefix}test.toklow.${SRC} ">" moses-test/${SRC}-${TRG}/${prefix}test/translated.${TRG} "2>" moses-test/${SRC}-${TRG}/${prefix}test/error.out
  show_exec ${TRAVATAR}/src/bin/mt-evaluator -ref ${PREPROC_DIR}/${PAIR}/${prefix}test.toklow.${TRG} moses-test/${SRC}-${TRG}/${prefix}test/translated.${TRG} "2>" /dev/null \| tee moses-test/${SRC}-${TRG}/${prefix}test/eval.out
done

