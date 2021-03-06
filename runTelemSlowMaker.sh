#!/bin/bash
if [ "$3" = "" ]
then
   echo "usage: `basename $0` <run no> <raw run ir> <root run dir>" 1>&2
   exit 1
fi

RUN=$1
RAW_RUN_DIR=$2
ROOT_RUN_DIR=$3


if [[ -d $ROOT_RUN_DIR ]]; then
    echo "Output dir exists"
elif [[ -d $RAW_RUN_DIR  ]]; then
    mkdir ${ROOT_RUN_DIR}
else
    echo "$RAW_RUN_DIR doesn't exist what are we suppposed to rootify?"
    exit 0;
fi



echo "Starting Slow File"
SLOW_FILE_LIST=`mktemp`
for file in ${RAW_RUN_DIR}/house/slowRate/*/*/slow*gz; 
  do
  if [[ -f $file ]]; then
      echo $file >> ${SLOW_FILE_LIST}
  fi
done

if  test `cat ${SLOW_FILE_LIST} | wc -l` -gt 0 ; then
    SLOW_ROOT_FILE=${ROOT_RUN_DIR}/slowFile${RUN}.root
    makeSlowRateTree ${SLOW_FILE_LIST} ${SLOW_ROOT_FILE}
    rm ${SLOW_FILE_LIST}
    echo "Done Slow Rate File"
else
    rm ${SLOW_FILE_LIST}
    echo "No Slow Rate Files"
fi
