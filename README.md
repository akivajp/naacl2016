# naacl2016
Codes for the experiments of NAACL 2016 long paper

Starting experiments on active learning + machine translation

  ./process.sh

contains all the currently implemented steps.

## External programs

Please build Moses toolkit with --with-mm option (Memory Mapped Suffix Array Phrase Table).

Please inc-giza-pp, a specialized version of GIZA++ word alignmer supporting incremental training.
https://github.com/akivajp/inc-giza-pp

Some scripts use Travatar toolkit and Ckylark structure parser.
Please install them and set the environment variables in script/config.sh.

