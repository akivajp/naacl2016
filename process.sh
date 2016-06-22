#!/bin/bash
set -e

#STEPCOUNT=100
THREADS=4

# Make log directory
mkdir -p log

# Get the data of WMT14 and EMEA corpora
script/get-data.sh en fr

# Run the preprocessing
script/run-preproc.sh en fr --threads=${THREADS}

# Train the language models
script/train-lm.sh en fr 5

for dtype in base-train both-train; do
  :
  script/train-moses.sh en fr ${dtype} --threads=${THREADS}
done

# Prepare data for growth methods
script/prepare-growth-corpora.sh en fr growth-corpus/en-fr --threads=${THREADS}

# Define simulation steps
simulate()
{
  ./script/simulate-growth.sh $1 $2 $3 $4 1 1 20 --threads=${THREADS}
  ./script/simulate-growth.sh $1 $2 $3 $4 20 2 15 --threads=${THREADS}
  ./script/simulate-growth.sh $1 $2 $3 $4 50 5 30 --threads=${THREADS}
  ./script/simulate-growth.sh $1 $2 $3 $4 200 10 30 --threads=${THREADS}
  ./script/simulate-growth.sh $1 $2 $3 $4 500 50 30 --threads=${THREADS}
  ./script/simulate-growth.sh $1 $2 $3 $4 2000 100 30 --threads=${THREADS}
  ./script/simulate-growth.sh $1 $2 $3 $4 5000 500 30 --threads=${THREADS}
  ./script/simulate-growth.sh $1 $2 $3 $4 20000 1000 30 --threads=${THREADS}
  ./script/simulate-growth.sh $1 $2 $3 $4 50000 5000 30 --threads=${THREADS}
}

# Run the simulation
simulate en fr 4gram-rand growth-corpus/en-fr/4gram-rand.en-fr
simulate en fr 4gram-freq growth-corpus/en-fr/4gram-freq.en-fr
simulate en fr sent-rand growth-corpus/en-fr/sent-rand
simulate en fr sent-by-4gram-freq growth-corpus/en-fr/sent-by-4gram-freq.en-fr
simulate en fr maxsubst-freq growth-corpus/en-fr/maxsubst-freq.en-fr
simulate en fr struct-freq growth-corpus/en-fr/struct-freq.en-fr
simulate en fr reduced-maxsubst-freq growth-corpus/en-fr/reduced-maxsubst-freq.en-fr
simulate en fr reduced-struct-freq growth-corpus/en-fr/reduced-struct-freq.en-fr

