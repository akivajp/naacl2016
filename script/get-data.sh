#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
source "${dir}/common.sh"

if [ ${#ARGS[@]} -lt 2 ]; then
  echo "usage: $0 langSrc langTrg" > /dev/stderr
  exit 1
fi

SRC=${ARGS[0]}
TRG=${ARGS[1]}
if [ ${SRC} == en ]; then
  PAIR=en-${TRG}
elif [ ${TRG} == en ]; then
  PAIR=en-${SRC}
elif [[ ${SRC} < ${TRG} ]]; then
  PAIR=${SRC}-${TRG}
else
  PAIR=${TRG}-${SRC}
fi

# Corpus URL
EURO_V7="http://www.statmt.org/wmt13/training-parallel-europarl-v7.tgz"
WMT14_DEV="http://www.statmt.org/wmt14/dev.tgz"
WMT14_TEST="http://www.statmt.org/wmt14/test.tgz"

EMEA_CS="http://opus.lingfil.uu.se/download.php?f=EMEA/cs-en.txt.zip"
EMEA_DE="http://opus.lingfil.uu.se/download.php?f=EMEA/de-en.txt.zip"
EMEA_FR="http://opus.lingfil.uu.se/download.php?f=EMEA/en-fr.txt.zip"
PATTR_FR="http://www.cl.uni-heidelberg.de/statnlpgroup/pattr/en-fr.tar.gz"
WP_FR="http://www.statmt.org/wmt14/medical-task/wp-medical-titles.fr-en.gz"
MED_DEVTEST="http://www.statmt.org/wmt14/medical-task/khresmoi-summary-test-set.tgz"

KFTT="http://www.phontron.com/kftt/download/kftt-data-1.0.tar.gz"
EIJIRO="/home/is/akiba-mi/project/corpora/eijiro"
ASPEC_JAEN="/home/is/neubig/exp/aspec/ja-en/data/"

get_corpus() {
  local LOCATION=$1
  if [[ ${LOCATION} =~ ^http:// ]]; then
    show_exec wget -c "$LOCATION" -O $(basename "$LOCATION")
  elif [[ -d ${LOCATION} ]]; then
    show_exec cp -r ${LOCATION} ./
  else
    echo "Invalid path: ${LOCATION}" > /dev/stderr
    exit 1
  fi
}

extract_euro_v7() {
  local ARCHIVE=$(basename "$1")
  local CONTENT1=$(tar tf $ARCHIVE | head -n 1)
  local BASE1=$(basename $CONTENT1)
  if [ ! -f "${BASE1}" ]; then
    show_exec tar zxvf $ARCHIVE
    show_exec mv training/* ./
    show_exec rmdir training
  fi
}

extract_emea() {
  local ARCHIVE=$(basename "$1")
  local LAST=$(unzip -l $ARCHIVE | tail -n 3 | head -n 1 | awk '{print $4}')
  if [ ! -f ${LAST} ]; then
    show_exec unzip -n $ARCHIVE
  fi
}

extract_wmt14_dev() {
  local ARCHIVE=$(basename "$1")
  local CONTENT1=$(tar tf $ARCHIVE | grep -E "\.(cs|de|en|fr)$" | head -n 1)
  local BASE1=$(basename $CONTENT1)
  if [ ! -f "${BASE1}" ]; then
    show_exec tar zxvf $ARCHIVE
    show_exec find dev/ -type f \| grep -v .sgm \| grep -E '"\.(cs|de|en|fr)$"' \| xargs -n 1 mv -t ./
    show_exec rm -rf dev
  fi
}

extract_pattr() {
  local ARCHIVE=$(basename "$1")
  local SRC=$2
  local TRG=$3
  local FILE1=pattr.${SRC}-${TRG}.description.${SRC}
  if [ ! -f "${FILE1}" ]; then
    show_exec tar zxvf $ARCHIVE
    show_exec find ${SRC}-${TRG}/ -type f \| grep -E '"\.(cs|de|en|fr)"' \| xargs -n 1 mv -t ./
    show_exec rm -rf ${SRC}-${TRG}
  fi
}

extract_wp() {
  local ARCHIVE=$(basename "$1")
  local SRC=$2
  local TRG=$3
  if [ ! -f "wp.${SRC}-${TRG}.${TRG}" ]; then
    show_exec zcat ${ARCHIVE} \| tee ">(cut -f1 > wp.${SRC}-${TRG}.${SRC})" \| cut -f2 \> wp.${SRC}-${TRG}.${TRG}
  fi
}

extract_med_devtest() {
  local ARCHIVE=$(basename "$1")
  local CONTENT1=$(tar tf $ARCHIVE | grep -E "\.(cs|de|en|fr)$" | head -n 1)
  local BASE1=$(basename $CONTENT1)
  if [ ! -f "${BASE1}" ]; then
    show_exec tar zxvf $ARCHIVE
    show_exec find khresmoi-summary-test-set/ -type f \| grep -E '"\.(cs|de|en|fr)$"' \| xargs -n 1 mv -t ./
    show_exec rm -rf khresmoi-summary-test-set
  fi
}

extract_kftt() {
  local ARCHIVE=$(basename "$1")
  local CONTENT1=$(tar tf $ARCHIVE | grep -E "\.(en|ja)$" | head -n 1)
  local BASE1=$(basename $CONTENT1)
  local STEM=$(basename $ARCHIVE .tar.gz)
  if [ ! -f "${BASE1}" ]; then
    show_exec tar zxvf $ARCHIVE
    show_exec find ${STEM} -type f \| grep -E '"orig/.*\.(en|ja)$"' \| xargs -n 1 mv -t ./
    show_exec rm -rf ${STEM}
  fi
}

extract_reijiro() {
  local DIRPATH=$1
  if [ ! -d ${DIRPATH} ]; then
    echo "Directory does not exist: ${DIRPATH}" > /dev/stderr
    exit 1
  fi
  local BASE1=$(ls $DIRPATH | grep -E "\.(en|ja)$" | head -n 1)
  if [ ! -f "${BASE1}" ]; then
    show_exec find ${DIRPATH}/ -type f \| grep -E '"\.(en|ja)$"' \| xargs -n 1 cp -t ./
  fi
}

extract_aspec() {
  local DIRPATH=$1
  if [ ! -d ${DIRPATH} ]; then
    echo "Directory does not exist: ${DIRPATH}" > /dev/stderr
    exit 1
  fi
  local BASE1=$(ls $DIRPATH | grep -E "\.(en|ja)$" | head -n 1)
  if [ ! -f "${BASE1}" ]; then
    show_exec find ${DIRPATH}/ -type f \| grep -E '"\.(en|ja)$"' \| xargs -n 1 cp -t ./
  fi
}

make_base() {
  SRC=$1
  TRG=$2
  if [ ! -f ${PREFIX_BASE}dev.${SRC}-${TRG}.${TRG} ]; then
    if [ -f europarl-v7.${SRC}-${TRG}.${SRC} ]; then
      local CORPUS=europarl-v7.${SRC}-${TRG}
    else
      local CORPUS=europarl-v7.${TRG}-${SRC}
    fi
    show_exec cp ${CORPUS}.${SRC} ${PREFIX_BASE}train.${SRC}-${TRG}.${SRC}
    show_exec cp ${CORPUS}.${TRG} ${PREFIX_BASE}train.${SRC}-${TRG}.${TRG}
    show_exec cp newstest2013.${SRC} ${PREFIX_BASE}test.${SRC}-${TRG}.${SRC}
    show_exec cp newstest2013.${TRG} ${PREFIX_BASE}test.${SRC}-${TRG}.${TRG}
    show_exec cp newssyscomb2009.${SRC} ${PREFIX_BASE}dev.${SRC}-${TRG}.${SRC}
    show_exec cp newssyscomb2009.${TRG} ${PREFIX_BASE}dev.${SRC}-${TRG}.${TRG}
  fi
}

make_add() {
  SRC=$1
  TRG=$2
  if [ ! -f ${PREFIX_ADD}dev.${SRC}-${TRG}.${TRG} ]; then
    local CORPORA=()
    if [ -f EMEA.${SRC}-${TRG}.${TRG} ]; then
      CORPORA+=(EMEA.${SRC}-${TRG})
    elif [ -f EMEA.${TRG}-${SRC}.${TRG} ]; then
      CORPORA+=(EMEA.${TRG}-${SRC})
    fi
    for file in pattr.${SRC}-${TRG}.*.${TRG}; do
      if [ -f $file ]; then
        CORPORA+=( $(basename $file .${TRG}) )
      fi
    done
    for file in pattr.${TRG}-${SRC}.*.${TRG}; do
      if [ -f $file ]; then
        echo $file
        CORPORA+=( $(basename $file .${TRG}) )
      fi
    done
    if [ -f wp.${SRC}-${TRG}.${TRG} ]; then
      CORPORA+=(wp.${SRC}-${TRG})
    fi
    echo CORPORA: ${CORPORA[@]}
    show_exec cat ${CORPORA[@]/%/.$SRC} \| pv -l \> ${PREFIX_ADD}train.${SRC}-${TRG}.${SRC}
    show_exec cat ${CORPORA[@]/%/.$TRG} \| pv -l \> ${PREFIX_ADD}train.${SRC}-${TRG}.${TRG}
    show_exec cp khresmoi-summary-test.${SRC} ${PREFIX_ADD}test.${SRC}-${TRG}.${SRC}
    show_exec cp khresmoi-summary-test.${TRG} ${PREFIX_ADD}test.${SRC}-${TRG}.${TRG}
    show_exec cp khresmoi-summary-dev.${SRC} ${PREFIX_ADD}dev.${SRC}-${TRG}.${SRC}
    show_exec cp khresmoi-summary-dev.${TRG} ${PREFIX_ADD}dev.${SRC}-${TRG}.${TRG}
  fi
}

make_dataset() {
  SRC=$1
  TRG=$2
  NAME=$3
  CORPORA=("$@")
  CORPORA=("${CORPORA[@]:3}")
  echo CORPORA: ${CORPORA[@]}
  show_exec cat ${CORPORA[@]/%/.$SRC} \| pv -l \> ${NAME}.${SRC}-${TRG}.${SRC}
  show_exec cat ${CORPORA[@]/%/.$TRG} \| pv -l \> ${NAME}.${SRC}-${TRG}.${TRG}
}

# Get the TM data
show_exec mkdir -p $CORPUS_DIR
show_exec pushd $CORPUS_DIR

if [ ${PAIR} == "en-fr" ]; then
  if [ ! -f DONE.get.en-fr ]; then
    get_corpus $EURO_V7
    #get_corpus $EMEA_CS
    #get_corpus $EMEA_DE
    get_corpus $EMEA_FR
    get_corpus $WMT14_DEV
    get_corpus $WMT14_TEST
    get_corpus $PATTR_FR
    get_corpus $WP_FR
    get_corpus $MED_DEVTEST
    show_exec touch DONE.get.en-fr
  fi
  if [ ! -f DONE.extract.en-fr ]; then
    show_exec extract_euro_v7 $EURO_V7
    show_exec extract_emea $EMEA_FR
    show_exec extract_pattr $PATTR_FR en fr
    show_exec extract_wmt14_dev $WMT14_DEV
    show_exec extract_wp $WP_FR en fr
    show_exec extract_med_devtest $MED_DEVTEST
    show_exec touch DONE.extract.en-fr
  fi
  if [ ! -f DONE.set.en-fr ]; then
#    show_exec make_base en fr
#    show_exec make_add en fr
    show_exec make_dataset en fr ${PREFIX_BASE}train europarl-v7.fr-en
    show_exec make_dataset en fr ${PREFIX_BASE}test newstest2013
    show_exec make_dataset en fr ${PREFIX_BASE}dev newssyscomb2009
    show_exec make_dataset en fr ${PREFIX_ADD}train EMEA.en-fr pattr.en-fr.{abstract,claims,description,title} wp.en-fr
    show_exec make_dataset en fr ${PREFIX_ADD}test khresmoi-summary-test
    show_exec make_dataset en fr ${PREFIX_ADD}dev khresmoi-summary-dev
    show_exec touch DONE.set.en-fr
  fi
elif [[ ${PAIR} == "en-ja" ]]; then
  if [ ! -f DONE.get.en-ja ]; then
    :
    get_corpus $KFTT
    show_exec touch DONE.get.en-ja
  fi
  if [ ! -f DONE.extract.en-ja ]; then
#    extract_kftt $KFTT
    extract_reijiro $EIJIRO
    extract_aspec $ASPEC_JAEN
    show_exec touch DONE.extract.en-ja
  fi
  if [ ! -f DONE.set.en-ja ]; then
#    show_exec make_dataset en ja ${PREFIX_BASE}train REIJI133-train
#    show_exec make_dataset en ja ${PREFIX_BASE}test REIJI133-test
#    show_exec make_dataset en ja ${PREFIX_BASE}dev REIJI133-dev
#    show_exec make_dataset en ja ${PREFIX_ADD}train kyoto-train
#    show_exec make_dataset en ja ${PREFIX_ADD}test kyoto-test
#    show_exec make_dataset en ja ${PREFIX_ADD}dev kyoto-dev
    show_exec make_dataset en ja ${PREFIX_BASE}train REIJI133-train kyoto-train
    show_exec make_dataset en ja ${PREFIX_ADD}test kyoto-test
    show_exec make_dataset en ja ${PREFIX_ADD}dev kyoto-dev
    show_exec make_dataset en ja ${PREFIX_ADD}train train
    show_exec make_dataset en ja ${PREFIX_ADD}test test
    show_exec make_dataset en ja ${PREFIX_ADD}dev dev
    show_exec touch DONE.set.en-ja
  fi
fi

show_exec popd

