#!/bin/bash

RMFILES=()
RMFILES+=(baseline-ngrams)
RMFILES+=(data)
RMFILES+=(lm)
RMFILES+=(log)
RMFILES+=(ja-en)
RMFILES+=(moses-*)

echo -n "Are you sure to remove files \"${RMFILES[@]}\"? [y/n]: "
read ANS
if [ "$ANS" == "y" ]; then
  echo exec: rm -rf "${RMFILES[@]}"
  rm -rf "${RMFILES[@]}"
fi

