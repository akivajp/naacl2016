#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE:-${(%):-%N}}")"; pwd)"
source "${dir}/common.sh"

if [[ $# != 4 ]]; then
    echo "Usage: $0 CORPUS SRC TRG TRAINDIR"
    exit 1
fi

CORPUS=$1
SRC=$2
TRG=$3
TRAINDIR=$4

abspath()
{
    local ABSPATHS=()
    for path in "$@"; do
      ABSPATHS+=(`echo $(cd $(dirname $path) && pwd)/$(basename $path)`)
    done
    echo "${ABSPATHS[@]}"
}

show_exec mkdir -p ${TRAINDIR}
show_exec rm -rf ${TRAINDIR}/{$SRC,$TRG}
show_exec ln -s $(abspath ${CORPUS}.${SRC}) ${TRAINDIR}/${SRC}
show_exec ln -s $(abspath ${CORPUS}.${TRG}) ${TRAINDIR}/${TRG}

show_exec ${INCGIZAPP}/plain2snt.out ${TRAINDIR}/{$SRC,$TRG} -txt1-vocab ${TRAINDIR}/${SRC}.vcb -txt2-vocab ${TRAINDIR}/${TRG}.vcb \> ${TRAINDIR}/log.plain2snt.${SRC}-${TRG}
if [ ! -f ${TRAINDIR}/${SRC}-${TRG}.cooc ]; then
    show_exec ${INCGIZAPP}/snt2cooc.out ${TRAINDIR}/{$SRC,$TRG}.vcb ${TRAINDIR}/${SRC}_${TRG}.snt \> ${TRAINDIR}/${SRC}-${TRG}.cooc 2\> ${TRAINDIR}/log.snt2cooc.${SRC}-${TRG} \&
    show_exec ${INCGIZAPP}/snt2cooc.out ${TRAINDIR}/{$TRG,$SRC}.vcb ${TRAINDIR}/${TRG}_${SRC}.snt \> ${TRAINDIR}/${TRG}-${SRC}.cooc 2\> ${TRAINDIR}/log.snt2cooc.${TRG}-${SRC} \&
    show_exec wait
else
    show_exec ${INCGIZAPP}/snt2cooc.out ${TRAINDIR}/{$SRC,$TRG}.vcb ${TRAINDIR}/${SRC}_${TRG}.snt ${TRAINDIR}/${SRC}-${TRG}.cooc \> ${TRAINDIR}/new.${SRC}-${TRG}.cooc 2\> ${TRAINDIR}/log.snt2cooc.${SRC}-${TRG} \&
    show_exec ${INCGIZAPP}/snt2cooc.out ${TRAINDIR}/{$TRG,$SRC}.vcb ${TRAINDIR}/${TRG}_${SRC}.snt ${TRAINDIR}/${TRG}-${SRC}.cooc \> ${TRAINDIR}/new.${TRG}-${SRC}.cooc 2\> ${TRAINDIR}/log.snt2cooc.${TRG}-${SRC} \&
    show_exec wait
    show_exec mv ${TRAINDIR}/new.${SRC}-${TRG}.cooc ${TRAINDIR}/${SRC}-${TRG}.cooc
    show_exec mv ${TRAINDIR}/new.${TRG}-${SRC}.cooc ${TRAINDIR}/${TRG}-${SRC}.cooc
fi

if [ ! -f ${TRAINDIR}/${TRG}-${SRC}.hhmm.last ]; then
    show_exec ${INCGIZAPP}/GIZA++ -S ${TRAINDIR}/${SRC}.vcb -T ${TRAINDIR}/${TRG}.vcb -C ${TRAINDIR}/${SRC}_${TRG}.snt -O ${TRAINDIR}/${SRC}-${TRG} -CoocurrenceFile ${TRAINDIR}/${SRC}-${TRG}.cooc -hmmiterations 5 -hmmdumpfrequency 5 -m1 5 -m3 0 -m4 0 \> ${TRAINDIR}/log.gizapp.${SRC}-${TRG} 2\> /dev/stdout \&
    show_exec ${INCGIZAPP}/GIZA++ -S ${TRAINDIR}/${TRG}.vcb -T ${TRAINDIR}/${SRC}.vcb -C ${TRAINDIR}/${TRG}_${SRC}.snt -O ${TRAINDIR}/${TRG}-${SRC} -CoocurrenceFile ${TRAINDIR}/${TRG}-${SRC}.cooc -hmmiterations 5 -hmmdumpfrequency 5 -m1 5 -m3 0 -m4 0 \> ${TRAINDIR}/log.gizapp.${TRG}-${SRC} 2\> /dev/stdout \&
#    show_exec ${INCGIZAPP}/GIZA++ -S ${TRAINDIR}/${SRC}.vcb -T ${TRAINDIR}/${TRG}.vcb -C ${TRAINDIR}/${SRC}_${TRG}.snt -O ${TRAINDIR}/${SRC}-${TRG} -CoocurrenceFile ${TRAINDIR}/${SRC}-${TRG}.cooc -hmmiterations 1 -hmmdumpfrequency 1 -m1 1 -m3 0 -m4 0 \> ${TRAINDIR}/log.gizapp.${SRC}-${TRG} 2\> /dev/stdout \&
#    show_exec ${INCGIZAPP}/GIZA++ -S ${TRAINDIR}/${TRG}.vcb -T ${TRAINDIR}/${SRC}.vcb -C ${TRAINDIR}/${TRG}_${SRC}.snt -O ${TRAINDIR}/${TRG}-${SRC} -CoocurrenceFile ${TRAINDIR}/${TRG}-${SRC}.cooc -hmmiterations 1 -hmmdumpfrequency 1 -m1 1 -m3 0 -m4 0 \> ${TRAINDIR}/log.gizapp.${TRG}-${SRC} 2\> /dev/stdout \&
    show_exec wait
else
    show_exec ${INCGIZAPP}/GIZA++ -S ${TRAINDIR}/${SRC}.vcb -T ${TRAINDIR}/${TRG}.vcb -C ${TRAINDIR}/${SRC}_${TRG}.snt -O ${TRAINDIR}/${SRC}-${TRG} -CoocurrenceFile ${TRAINDIR}/${SRC}-${TRG}.cooc -hmmiterations 1 -hmmdumpfrequency 1 -m1 1 -m3 0 -m4 0 -stepk 1 -oldTrPrbs ${TRAINDIR}/${SRC}-${TRG}.thmm.last -oldAlPrbs ${TRAINDIR}/${SRC}-${TRG}.hhmm.last \> ${TRAINDIR}/log.gizapp.${SRC}-${TRG} 2\> /dev/stdout \&
    show_exec ${INCGIZAPP}/GIZA++ -S ${TRAINDIR}/${TRG}.vcb -T ${TRAINDIR}/${SRC}.vcb -C ${TRAINDIR}/${TRG}_${SRC}.snt -O ${TRAINDIR}/${TRG}-${SRC} -CoocurrenceFile ${TRAINDIR}/${TRG}-${SRC}.cooc -hmmiterations 1 -hmmdumpfrequency 1 -m1 1 -m3 0 -m4 0 -stepk 1 -oldTrPrbs ${TRAINDIR}/${TRG}-${SRC}.thmm.last -oldAlPrbs ${TRAINDIR}/${TRG}-${SRC}.hhmm.last \> ${TRAINDIR}/log.gizapp.${TRG}-${SRC} 2\> /dev/stdout \&
      show_exec wait
fi

for file in ${TRAINDIR}/*hmm.?; do
  if [ -f ${file} ]; then
    show_exec mv $file ${file%.*}.last
  fi
done

show_exec ${MOSES}/scripts/training/giza2bal.pl -d ${TRAINDIR}/${SRC}-${TRG}.Ahmm.last -i ${TRAINDIR}/${TRG}-${SRC}.Ahmm.last \> ${TRAINDIR}/${SRC}-${TRG}.bal 2\> ${TRAINDIR}/log.giza2bal
show_exec cat ${TRAINDIR}/${SRC}-${TRG}.bal \| $MOSES/bin/symal -alignment="grow" -diagonal="yes" -final="yes" -both="yes" \> ${TRAINDIR}/align.txt

