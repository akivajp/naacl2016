#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
source "${dir}/common.sh"

if [ ${#ARGS[@]} -lt 3 ]; then
  echo "usage: $0 src trg growthDir"
  exit 1
fi

SRC=$1
TRG=$2
WORKDIR=$3

show_exec ${dir}/prepare-growth-4gram-freq.sh ${SRC} ${TRG} ${WORKDIR} --threads=${THREADS}
show_exec ${dir}/prepare-growth-4gram-rand.sh ${SRC} ${TRG} ${WORKDIR} --threads=${THREADS}
show_exec ${dir}/prepare-growth-sent-rand.sh ${SRC} ${TRG} ${WORKDIR} --threads=${THREADS}
show_exec ${dir}/prepare-growth-sent-by-4gram-freq.sh ${SRC} ${TRG} ${WORKDIR} --threads=${THREADS}
show_exec ${dir}/prepare-growth-maxsubst-freq.sh ${SRC} ${TRG} ${WORKDIR} --threads=${THREADS}
show_exec ${dir}/prepare-growth-struct-freq.sh ${SRC} ${TRG} ${WORKDIR} --threads=${THREADS}
show_exec ${dir}/prepare-growth-reduced-maxsubst-freq.sh ${SRC} ${TRG} ${WORKDIR} --threads=${THREADS}
show_exec ${dir}/prepare-growth-reduced-struct-freq.sh ${SRC} ${TRG} ${WORKDIR} --threads=${THREADS}

