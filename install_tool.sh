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

apt-get install -y python python-pip &&
apt-get install -y python3 &&
apt-get install -y psmisc && # for killall, used in prepare_instance.sh script

pip install -r "$DIR/requirements.txt" &&
cd onnx-tensorflow && pip install -e . && cd .. ## ONNX-TF
