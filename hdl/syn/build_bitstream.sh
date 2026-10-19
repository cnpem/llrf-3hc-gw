#! /bin/bash

make clean

python3 -m venv .lowlevelhw
source .lowlevelhw/bin/activate

./install_lowlevelhw_env.sh
./gen_essffw_regbanks.sh
hdlmake
make synthesize
