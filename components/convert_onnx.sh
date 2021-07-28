#!/bin/bash

TOOL_NAME=verapak
VERSION_STRING=v1

# check arguments
if [ "$1" != ${VERSION_STRING} ]; then
	echo "Expected first argument to be the version string '$VERSION_STRING', instead got '$1'" 1>&2
	exit 1
fi

if [ "$#" -ne 3 ]; then
	echo "Expected 3 arguments (got $#): \"$VERSION_STRING\" <in.onnx> <out.pb>" 1>&2
	exit 1
fi

ONNX_IN=$2
TF_OUT=$3

cp $ONNX_IN .onnx.tmp
onnx-tf convert -i .onnx.tmp -o .tf.tmp 2>&1
cp .tf.tmp $TF_OUT
rm -f .onnx.tmp .tf.tmp

