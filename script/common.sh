#!/bin/bash

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
stamp=$(date +"%Y/%m/%d %H:%M:%S")

source ${dir}/config.sh

show_exec()
{
  local pane=""
  local stamp=$(date +"%Y/%m/%d %H:%M:%S")
  local PANE=$(tmux display -p "#I.#P" 2> /dev/null)
  if [ "${PANE}" ]; then
    pane=":${PANE}"
  fi
  if [ "${LOG}" ]; then
    local LOGDIR=$(dirname $LOG)
    if [ ! -d "${LOGDIR}" ]; then
      mkdir ${LOGDIR}
    fi
  fi
  echo "[exec ${stamp} on ${HOST}${pane}] $*" | tee -a ${LOG}
  eval "$@"

  if [ $? -gt 0 ]
  then
    local red=31
    local msg="[error ${stamp} on ${HOST}${pane}]: $@"
    echo -e "\033[${red}m${msg}\033[m" | tee -a ${LOG}
    exit 1
  fi
}

try_timeout()
{
  local pane=""
  local stamp=$(date +"%Y/%m/%d %H:%M:%S")
  local PANE=$(tmux display -p "#I.#P" 2> /dev/null)
  if [ "${PANE}" ]; then
    pane=":${PANE}"
  fi
  local duration=${1}
  let count=${2}+0
  shift 2
  if [ "${count}" -ge 1 ]; then
    echo "[exec duration:${duration}, trial:${count}, ${stamp} on ${HOST}${pane}] $@" | tee -a ${LOG}
    eval timeout $duration "$@"
    if [ $? -gt 0 ]
    then
      let count=${count}-1
      try_timeout $duration $count "$@"
    fi
  else
    if [ $? -gt 0 ]; then
      local red=31
      local msg="[error ${stamp} on ${HOST}${pane}]: $@"
      echo -e "\033[${red}m${msg}\033[m" | tee -a ${LOG}
      exit 1
    fi
  fi
}

proc_args()
{
  ARGS=()
  OPTS=()

  while [ $# -gt 0 ]
  do
    arg=$1
    case $arg in
      --*=* )
        opt=${arg#--}
        name=${opt%=*}
        var=${opt#*=}
        eval "opt_${name}=${var}"
        ;;
      --* )
        name=${arg#--}
        eval "opt_${name}=1"
        ;;
      -* )
        OPTS+=($arg)
        ;;
      * )
        ARGS+=($arg)
        ;;
    esac

    shift
  done
}

abspath()
{
  ABSPATHS=()
  for path in "$@"; do
    ABSPATHS+=(`echo $(cd $(dirname $path) && pwd)/$(basename $path)`)
  done
  echo "${ABSPATHS[@]}"
}

ask_continue()
{
  local testfile=$1
  local REP=""
  if [ "${testfile}" ]; then
    if [ ! -e ${testfile} ]; then
      return
    else
      echo -n "\"${testfile}\" is found. do you want to continue? [y/n]: "
    fi
  else
    echo -n "do you want to continue? [y/n]: "
  fi
  while [ 1 ]; do
    read REP
    case $REP in
      y*|Y*) break ;;
      n*|N*) exit ;;
      *) echo -n "type y or n: " ;;
    esac
  done
}

get_pair()
{
  SRC=$1
  TRG=$2
  if [ ${SRC} == en ]; then
    echo en-${TRG}
  elif [ ${TRG} == en ]; then
    echo en-${SRC}
  elif [[ ${SRC} < ${TRG} ]]; then
    echo ${SRC}-${TRG}
  else
    echo ${TRG}-${SRC}
  fi
}

proc_args $*

if [ "${opt_threads}" ]; then
  THREADS=${opt_threads}
fi

