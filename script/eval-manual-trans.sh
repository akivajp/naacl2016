#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
source "${dir}/common.sh"

if [ ${#ARGS[@]} -ne 7 ]; then
  echo "usage: lang_src lang_trg name json_file start_lines step_lines step_count"
  echo ""
  echo "options:"
  echo "  --confidence={1,2,3}  threshold for confidence level"
  exit 1
fi

SRC=${ARGS[0]}
TRG=${ARGS[1]}
NAME=${ARGS[2]}

JSONFILE=${ARGS[3]}
STARTLINES=${ARGS[4]}
STEPLINES=${ARGS[5]}
STEPCOUNT=${ARGS[6]}
let STOP="${STARTLINES}+${STEPLINES}*${STEPCOUNT}"

#TIMEOUT=120m
TIMEOUT=240m
TRIAL=20

SIMDIR=manual-growth
WORKDIR=${SIMDIR}/${SRC}-${TRG}/${NAME}/${STARTLINES}+${STEPLINES}n
if [[ "${opt_confidence}" ]]; then
  WORKDIR=${SIMDIR}/${SRC}-${TRG}/${NAME}+${opt_confidence}/${STARTLINES}+${STEPLINES}n
fi
TRAINBASE=${WORKDIR}/incr-moses
COMMONBASE=${SIMDIR}/${SRC}-${TRG}/base/incr-moses
LMBASE=lm/5

if [[ ${SRC} == "en" ]]; then
  PAIR=en-${TRG}
else
  PAIR=en-${SRC}
fi

CORPUS_BASE_TRAIN=${PREPROC_DIR}/${PAIR}/${PREFIX_BASE}train.toklow
CORPUS_BASE_TEST=${PREPROC_DIR}/${PAIR}/${PREFIX_BASE}test.toklow
CORPUS_BASE_DEV=${PREPROC_DIR}/${PAIR}/${PREFIX_BASE}dev.toklow
CORPUS_ADD_TRAIN=${PREPROC_DIR}/${PAIR}/${PREFIX_ADD}train.toklow
CORPUS_ADD_TEST=${PREPROC_DIR}/${PAIR}/${PREFIX_ADD}test.toklow
CORPUS_ADD_DEV=${PREPROC_DIR}/${PAIR}/${PREFIX_ADD}dev.toklow

if [ ! -d "${WORKDIR}" ]; then
  show_exec mkdir -p $WORKDIR
fi
LOG=$(abspath $WORKDIR/log)

increment() {
  if [ ! -f ${WORKDIR}/new.${SRC} ]; then
    NUMLINES=${STARTLINES}
  else
    NUMLINES=${STEPLINES}
  fi
  show_exec head -n ${NUMLINES} ${WORKDIR}/remain.${SRC} \> ${WORKDIR}/new.${SRC}
  show_exec head -n ${NUMLINES} ${WORKDIR}/remain.${TRG} \> ${WORKDIR}/new.${TRG}
  let OFFSET=${NUMLINES}+1
  show_exec tail -n +${OFFSET} ${WORKDIR}/remain.${SRC} \> ${WORKDIR}/remain.tail.${SRC}
  show_exec tail -n +${OFFSET} ${WORKDIR}/remain.${TRG} \> ${WORKDIR}/remain.tail.${TRG}
  show_exec mv ${WORKDIR}/remain.tail.${SRC} ${WORKDIR}/remain.${SRC}
  show_exec mv ${WORKDIR}/remain.tail.${TRG} ${WORKDIR}/remain.${TRG}
}

grow() {
  if [ ! -f $WORKDIR/growing.${SRC} ]; then
    show_exec cp $WORKDIR/orig.${SRC} $WORKDIR/growing.${SRC}
    show_exec cp $WORKDIR/orig.${TRG} $WORKDIR/growing.${TRG}

    show_exec cp ${LMBASE}/${SRC}-${TRG}.${TRG}.arpa ${WORKDIR}/add-merged.${TRG}.arpa
  fi
  touch $WORKDIR/added.{$SRC,$TRG}
  if [ -f $WORKDIR/new.${SRC} ]; then
    show_exec cp $WORKDIR/growing.${SRC} $WORKDIR/growing.prev.${SRC}
    show_exec cat $WORKDIR/new.${SRC} ">>" $WORKDIR/growing.${SRC}
    show_exec cat $WORKDIR/new.${SRC} ">>" $WORKDIR/added.${SRC}
    show_exec cp $WORKDIR/growing.${TRG} $WORKDIR/growing.prev.${TRG}
    show_exec cat $WORKDIR/new.${TRG} ">>" $WORKDIR/growing.${TRG}
    show_exec cat $WORKDIR/new.${TRG} ">>" $WORKDIR/added.${TRG}

    #show_exec ${TRAVATAR}/src/kenlm/lm/lmplz -o ${ORDER} -S 50% -T /tmp \< ${WORKDIR}/added.${TRG} \> ${WORKDIR}/added.${TRG}.arpa
    show_exec ${SRILM}/ngram-count -order 5 -text ${WORKDIR}/added.${TRG} -lm ${WORKDIR}/added.${TRG}.arpa
    show_exec ~/usr/local/mosesdecoder/scripts/ems/support/interpolate-lm.perl --name ${WORKDIR}/add-merged.${TRG}.arpa --lm \"${LMBASE}/${SRC}-${TRG}.${TRG}.arpa,${WORKDIR}/added.${TRG}.arpa\" --tuning ${CORPUS_ADD_DEV}.${TRG} --srilm ${SRILM}
  fi
}

test_moses() {
  local L=$(wc -l $WORKDIR/added.${SRC} | cut -d ' ' -f 1)
  local W=$(wc -w $WORKDIR/added.${SRC} | cut -d ' ' -f 1)
  show_exec mkdir -p ${TRAINBASE}/${L}/output
  try_timeout ${TIMEOUT} ${TRIAL} $MOSES/bin/moses -threads ${THREADS} -f ${TRAINBASE}/${PREFIX_ADD}tuned.ini \< ${CORPUS_ADD_TEST}.${SRC} \> ${TRAINBASE}/${L}/output/translated-${PREFIX_ADD}test.${TRG} "2>>" ${TRAINBASE}/${L}/output/error-${PREFIX_ADD}test.${TRG}
  show_exec wait
  show_exec $TRAVATAR/src/bin/mt-evaluator -ref ${CORPUS_ADD_TEST}.${TRG} ${TRAINBASE}/${L}/output/translated-${PREFIX_ADD}test.${TRG} \> ${TRAINBASE}/${L}/output/bleu-score-${PREFIX_ADD}test.out 2> /dev/null
  local stamp=$(date +"%Y/%m/%d %H:%M:%S")
  BLEU=$(cat ${TRAINBASE}/last/output/bleu-score-${PREFIX_ADD}test.out | grep -o "BLEU = [^,]*")
  if [[ ${L} -eq 0 ]]; then
    local DURATION=0
  else
    local DURATION=$(./script/extract-from-json.py --output=d ${JSONFILE} ${L})
  fi
  echo "Lines=$L, Words=$W, $BLEU, Duration=${DURATION}, Done=[$stamp]" >> $WORKDIR/bleu-scores-${PREFIX_ADD}test.out
}

mert_moses() {
  TUNEDIR=$1
  TESTSRC=$2
  TESTTRG=$3
  CONFIG=$4
  if [ ! -f ${TUNEDIR}/mert-work/moses.ini ]; then
    show_exec mkdir -p ${TUNEDIR}
    show_exec pushd ${TUNEDIR}
    show_exec $MOSES/scripts/training/mert-moses.pl $TESTSRC $TESTTRG ${MOSES}/bin/moses $CONFIG --mertdir $MOSES/bin --threads ${THREADS} 2\> mert.out
    show_exec popd
  fi
}

extract() {
  local LCODE=$1
  local JSONFILE=$2
  local OUTPUT=$3
  if [[ "${LCODE}" == "${SRC}" ]]; then
    local SIDE=s
  elif [[ "${LCODE}" == "${TRG}" ]]; then
    local SIDE=t
  else
    echo "Invalide language: ${LCODE}" > /dev/stderr
    exit 1
  fi
  local options=""
  if [[ "${opt_confidence}" ]]; then
    options="--threshold=${opt_confidence}"
  fi
  case ${LCODE} in
    ja) show_exec script/extract-from-json.py ${options} --output=${SIDE} ${JSONFILE} \| ${KYTEA}/src/bin/kytea -notags \| sed -e "'s/|/ -BAR- /g'" -e "'s/\\\\//g'" \| ${TRAVATAR}/script/tree/lowercase.pl \| pv -Wl \> ${WORKDIR}/remain.${LCODE};;
    *)  show_exec script/extract-from-json.py ${options} --output=${SIDE} ${JSONFILE} \| ${TRAVATAR}/src/bin/tokenizer \| sed -e "'s/|/ -BAR- /g'" \| ${TRAVATAR}/script/tree/lowercase.pl \| pv -Wl \> ${WORKDIR}/remain.${LCODE};;
  esac
}

if [ ! -f $WORKDIR/remain.${TRG} ]; then
  # set-up
  show_exec cp ${CORPUS_BASE_TRAIN}.${SRC} $WORKDIR/orig.${SRC}
  show_exec cp ${CORPUS_BASE_TRAIN}.${TRG} $WORKDIR/orig.${TRG}
  grow
  extract ${SRC} ${JSONFILE} ${WORKDIR}/remain.${SRC}
  extract ${TRG} ${JSONFILE} ${WORKDIR}/remain.${TRG}
#  show_exec script/extract-from-json.py --output=s ${JSONFILE} \| pv -Wl \> ${WORKDIR}/remain.${SRC}
#  show_exec script/extract-from-json.py --output=t ${JSONFILE} \| pv -Wl \> ${WORKDIR}/remain.${TRG}
fi

L=$(wc -l $WORKDIR/added.${SRC} | cut -d ' ' -f 1)
if [ ! -f ${TRAINBASE}/0/model/moses.ini ]; then
  # first training step
  if [ ! -f ${COMMONBASE}/moses.ini ]; then
    # training common base
    show_exec script/incr-train-moses.sh ${SRC} ${TRG} ${WORKDIR} ${COMMONBASE}
  fi
  mert_moses ${COMMONBASE}/mert-${PREFIX_ADD}dev $(abspath $CORPUS_ADD_DEV.{$SRC,$TRG} ${COMMONBASE}/moses.ini)
  # copying base training directory
  show_exec cp -rf ${COMMONBASE} ${TRAINBASE}
  show_exec cat ${COMMONBASE}/0/model/moses.ini \| sed -e  "'s!${COMMONBASE}!${TRAINBASE}!g'" \> ${TRAINBASE}/0/model/moses.ini
  show_exec cat ${COMMONBASE}/moses.ini \| sed -e  "'s!${COMMONBASE}!${TRAINBASE}!g'" \> ${TRAINBASE}/moses.ini
  show_exec cat ${COMMONBASE}/mert-${PREFIX_ADD}dev/mert-work/moses.ini \| sed -e "'s!${COMMONBASE}!${TRAINBASE}!g'" -e "'s!${LMBASE}/${SRC}-${TRG}.${TRG}.blm!${WORKDIR}/add-merged.${TRG}.arpa!'" \> ${TRAINBASE}/${PREFIX_ADD}tuned.ini
  show_exec rm -rf ${TRAINBASE}/mert-*
  show_exec rm ${TRAINBASE}/last
  show_exec ln -s $(abspath ${TRAINBASE}/0) ${TRAINBASE}/last
fi

if [ ! -f ${TRAINBASE}/${L}/model/moses.ini ]; then
  show_exec script/incr-train-moses.sh $SRC $TRG ${WORKDIR} ${TRAINBASE}
fi

if [ ! -f ${TRAINBASE}/last/output/bleu-score-${PREFIX_ADD}test.out ]; then
  if [ "${opt_skip_next}" ]; then
    echo "[Skipping this step: ${L}]"
  else
    echo "Current Step: ${L}"
    test_moses
  fi
fi

while [ -s ${WORKDIR}/remain.${SRC} ]; do
  L=$(wc -l $WORKDIR/added.${SRC} | cut -d ' ' -f 1)
  if [ "${L}" -ge ${STOP} ]; then
    break
  fi
  increment
  grow
  show_exec script/incr-train-moses.sh $SRC $TRG ${WORKDIR} ${TRAINBASE}
  test_moses
done

show_exec echo "Evaluation finished!"
date

