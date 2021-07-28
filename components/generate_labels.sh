#!/bin/bash

TOOL_NAME=verapak
VERSION_STRING=v1

# check arguments
if [ "$1" != ${VERSION_STRING} ]; then
	echo "Expected first argument to be the version string '$VERSION_STRING', instead got '$1'" 1>&2
	exit 1
fi

if [ "$#" -ne 4 ]; then
	echo "Expected 4 arguments (got $#): \"$VERSION_STRING\" <labels_out.pb> <shape> <intended_index>" 1>&2
	exit 1
fi

OUT_F=$2
IFS=", " SHAPE=(`echo $3 | tr "?" "1"`)
INTEND=$4

VALUE=""
DIM=1

for DIM_N in ${SHAPE[@]}; do
	DIM=`bc -l <<< "$DIM * $DIM_N"`
done

for it in $(seq -s " " 0 $DIM); do
	if [ $it == "$INTEND" ]; then
		VALUE=${VALUE}1
	elif (( $it < $DIM )); then
		VALUE=${VALUE}0
	fi
	if (( $it + 1 < $DIM )); then
		VALUE=${VALUE},
	fi
done

pb_creator --shape="${SHAPE[*]}" --value="$VALUE" --output="$OUT_F"

