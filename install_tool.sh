#!/bin/bash

TOOL_NAME=verapak
VERSION_STRING=v1

# check arguments
if [ "$#" -ne 1 ]; then
	echo "Expected one argument (got $#): '$VERSION_STRING' (version string)"
	exit 1
fi

if [ "$1" != ${VERSION_STRING} ]; then
	echo "Expected first argument (version string) '$VERSION_STRING', got '$1'"
	exit 1
fi

echo "Installing $TOOL_NAME"
DIR=$(dirname $(realpath $0))

#apt-get install -y python python-pip &&
#apt-get install -y python3 &&
#apt-get install -y psmisc && # for killall, used in prepare_instance.sh script

source activate tensorflow_p37

#pip2 install -r "$DIR/requirements.txt" &&
git submodule update --init --recursive
docker build -t onnx-tf:latest -f Dockerfile.onnxtf .
docker build -t pb_creator:latest -f Dockerfile.pb_creator .

(cd GraphWrangler && docker build -t graph_wrangler:latest .)

ln -s $PWD/onnx-tf /usr/local/bin/onnx-tf
ln -s $PWD/verapak /usr/local/bin/verapak
ln -s $PWD/GraphWrangler/graph_wrangler /usr/local/bin/graph_wrangler
ln -s $PWD/pb_creator /usr/local/bin/pb_creator

# install Verapak
git clone https://github.com/formal-verification-research/ARFramework.git
(cd ARFramework && docker build -t verapak:latest .)

