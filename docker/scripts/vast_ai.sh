#!/bin/bash

# Bash Script to Install kohya_ss on a Vast ai Machine
# tested with RTX 3090 and pytorch/pytorch_2.0.0-cuda11.7-cudnn8-runtime image

#install necessary tools
apt update
apt install -y libgl1 nano screen unzip # nano screen unzip optional
pip install cmake
pip install lit
pip install gdown #optional

# clone the repo
git clone https://github.com/bmaltais/kohya_ss

# run setup
bash kohya_ss/setup.sh -vvv

# install newer xformers and torchvision package
pip install xformers==0.0.19
pip install torchvision==0.1.9

# export environment variables
cp $(ls /opt/conda/lib/python3.10/site-packages/bitsandbytes/*cuda*.so | grep -v nocublaslt | tail -1) /opt/conda/lib/python3.10/site-packages/bitsandbytes/libbitsandbytes_cpu.so
export LD_LIBRARY_PATH=/opt/conda/lib:$LD_LIBRARY_PATH
export MKL_THREADING_LAYER=1
echo 'export LD_LIBRARY_PATH=/opt/conda/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
echo 'export MKL_THREADING_LAYER=1' >> ~/.bashrc

# change gui.sh
rm kohya_ss/gui.sh

cat <<EOF > kohya_ss/gui.sh
#!/usr/bin/env bash

# This gets the directory the script is run from so pathing can work relative to the script where needed.
SCRIPT_DIR=\$(cd -- "\$(dirname -- "\$0")" && pwd)

# Step into GUI local directory
cd "\$SCRIPT_DIR"

# Activate the virtual environment
source "\$SCRIPT_DIR/venv/bin/activate"

# If the requirements are validated, run the kohya_gui.py script with the command-line arguments
python "\$SCRIPT_DIR/kohya_gui.py" "\$@"
EOF

# make executable
chmod +x kohya_ss/gui.sh
