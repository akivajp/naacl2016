#!/bin/bash
set -e

CORES=`nproc`
WD=`pwd`
SD="$(cd "$(dirname $0)"; pwd)"

# Install desired packages

#TD=$WD/tools
TD=$HOME/usr/local

mkdir -p $TD/download

################### Language Independent Tools ############################

# Install GIZA++

if [[ ! -e $TD/giza-pp ]]; then
    cd $TD
    git clone git@github.com:moses-smt/giza-pp.git giza-pp
    cd $TD/giza-pp
    make -j $CORES
    cp GIZA++-v2/GIZA++ GIZA++-v2/*.out mkcls-v2/mkcls .
fi

# Install Inc-GIZA++
if [[ ! -e $TD/inc-giza-pp ]]; then
    cd $TD
    svn checkout http://inc-giza-pp.googlecode.com/svn/trunk/ inc-giza-pp
    patch -p0 < $SD/files/inc-giza-pp.diff
    cd $TD/inc-giza-pp
    make -j $CORES
    cp GIZA++-v2/GIZA++ GIZA++-v2/*.out mkcls-v2/mkcls .
fi

# Install Nile and its dependencies
if [[ ! -e $TD/nile ]]; then
 
    git clone https://github.com/neubig/nile.git $TD/nile
    # Install svector
    cd $TD/nile/svector
    python setup.py install --user
    # Install pyglog
    cd $TD/nile/pyglog
    python setup.py install --user

fi

if [[ ! -e $TD/nile/model ]]; then
    mkdir -p $TD/nile/model
    wget -P $TD/nile/model http://www.phontron.com/travatar/download/nile-en-ja.model
fi

# Install travatar
if [[ ! -e $TD/travatar ]]; then
    git clone https://github.com/neubig/travatar.git $TD/travatar
    
    cd $TD/travatar
    autoreconf -i
    ./configure
    make -j $CORES 
fi

# Install Egret
if [[ ! -e $TD/egret ]]; then

    git clone https://github.com/neubig/egret.git $TD/egret 
    cd $TD/egret
    make -j $CORES 

fi

# Install Egret
if [[ ! -e $TD/Ckylark ]]; then

    git clone https://github.com/odashi/Ckylark.git $TD/Ckylark 
    cd $TD/Ckylark
    autoreconf -i
    ./configure
    make -j $CORES 
    
    # Get chinese models (temporary)
    cd $TD/Ckylark/data
    wget http://www.phontron.com/download/ckylark-ctb.tar.gz
    tar -xzf ckylark-ctb.tar.gz
    rm ckylark-ctb.tar.gz

    # Unzip models
    gunzip $TD/Ckylark/data/*.gz

fi

# Install KyTea
if [[ ! -e $TD/bin/kytea ]]; then
    git clone https://github.com/neubig/kytea.git $TD/kytea
    
    cd $TD/kytea
    autoreconf -i
    ./configure --prefix=$TD
    gunzip data/model.bin.gz
    make -j $CORES
    make install

    # Install the chinese model
    wget -P $TD/kytea/data http://www.phontron.com/kytea/download/model/ctb-0.4.0-5.mod.gz
    gunzip $TD/kytea/data/ctb-0.4.0-5.mod.gz
fi

# Install Moses with MMSAPT (for incremental training)
if $TD/mosesdecoder/bin/moses 2>&1 | grep Mmsapt; then
    echo "Moses with mmsapt is installed"
else
    cd $TD
    if [ ! -d mosesdecoder ]; then
        git clone git@github.com:moses-smt/mosesdecoder.git mosesdecoder
    fi
    cd $TD/mosesdecoder
    echo ./bjam -j${CORES} --with-mm
    ./bjam -j${CORES} --with-mm
fi

################### Finish #################################################

echo "Finished getting tools!"

