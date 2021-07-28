#!/bin/bash

TOOL_NAME=verapak
VERSION_STRING=v1

# check arguments
if [ "$1" != ${VERSION_STRING} ]; then
	echo "Expected first argument to be the version string '$VERSION_STRING', instead got '$1'" 1>&2
	exit 1
fi

if [[ "$#" -ne 3 && "$#" -ne 4 ]]; then
	echo "Expected 3 or 4 arguments (got $#): \"$VERSION_STRING\" <in.pb> <out.pb> [negate : bool]" 1>&2
	exit 1
fi

TF_IN=$2
TF_OUT=$3
if [ "$4" == "" ]; then
	DO_NEG="False"
else
	DO_NEG=$4
fi

cp $TF_IN .tf_in.tmp
graph_wrangler main.py .tf_in.tmp .tf_out.tmp True $DO_NEG
cp .tf_out.tmp $TF_OUT
rm -f .tf_in.tmp .tf_out.tmp
