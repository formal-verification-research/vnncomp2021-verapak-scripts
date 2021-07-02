#!/bin/bash
# six arguments, first is "v1", second is a benchmark category itentifier string such as "acasxu", third is path to the .onnx file, fourth is path to .vnnlib file, fifth is a path to the results file, and sixth is a timeout in seconds.

TOOL_NAME=verapak
VERSION_STRING=v1

CONTAINER="verapak_container"
IMAGE="verapak:latest"
CONFIG_FILE="out/verapak.conf"

# check arguments
if [ "$#" -ne 6 ]; then
	echo "Expected six arguments (got $#): '$VERSION_STRING' (version string), benchmark_category, onnx_file, vnnlib_file, results_file, timeout (sec)"
	exit 1
fi

if [ "$1" != ${VERSION_STRING} ]; then
	echo "Expected first argument (version string) '$VERSION_STRING', got '$1'"
	exit 1
fi

CATEGORY=$2
ONNX_FILE=$3
VNNLIB_FILE=$4
RESULTS_FILE=$5
TIMEOUT=$6

echo "Running benchmark instance in category '$CATEGORY' with onnx file '$ONNX_FILE', vnnlib file '$VNNLIB_FILE', results file $RESULTS_FILE, and timeout $TIMEOUT"

# setup environment variable for tool (doing it earlier won't be persistent with docker)"
#DIR=$(dirname $(dirname $(realpath $0)))
#export PYTHONPATH="$PYTHONPATH:$DIR/src"

# Read parameters from file
readarray -t parameters <<< `grep -v "^[[:space:]]*#" $CONFIG_FILE | grep -v "^[[:space:]]*$"`

# Run the tool
if [ "${parameters[4]}" == *","* ] ; then
	radius_flag="verification_radius_array"
else
	radius_flag="verification_radius"
fi

if [ "${parameters[5]}" == *","* ] ; then
	granularity_flag="granularity_array"
else
	granularity_flag="granularity"
fi

if [ "${parameters[8]}" != "/" ] ; then
	averages=--class_averages="${parameters[8]}"
else
	averages=""
fi

(sleep $TIMEOUT; docker kill $CONTAINER 2> /dev/null && echo "timeout" > ~timeout && exit 124) & docker run --rm --name "$CONTAINER" -t -v "$PWD:/verapak/tensorflow/in" verapak:latest ARFramework_main --root_dir="/verapak/tensorflow/in" --output_dir="${parameters[0]}" --graph="${parameters[1]}" --input_layer="${parameters[2]}" --output_layer="${parameters[3]}" --$radius_flag="${parameters[4]}" --$granularity_flag="${parameters[5]}" --initial_activation="${parameters[6]}" --label_proto="${parameters[7]}" $averages --num_threads=${parameters[9]} --num_abstractions=${parameters[10]} --fgsm_balance_factor=${parameters[11]} --modified_fgsm_dim_selection="${parameters[12]}" --refinement_dim_selection="${parameters[13]}" --label_layer="${parameters[14]}" --gradient_layer="${parameters[15]}" --terminate_on_counterexample=true


# Write results file
RESULT_CODE=$?
timeout=`cat ~timeout 2> /dev/null`
(rm ~timeout 2> /dev/null)
if [ $RESULT_CODE -eq 3 ] ; then
	echo "violated" > $RESULTS_FILE
elif [ $RESULT_CODE -eq 2 ] ; then
	echo "" > $RESULTS_FILE
elif [ $RESULT_CODE -eq 1 ] ; then
	echo "error" > $RESULTS_FILE
elif [ $RESULT_CODE -eq 0 ] ; then
	echo "holds" > $RESULTS_FILE
elif [ "$timeout" == "timeout" ] ; then
	echo "TIMEOUT : $TIMEOUT sec : exit_$RESULT_CODE"
	echo "timeout" > $RESULTS_FILE
else
	echo "error_exit_code_$RESULT_CODE" > $RESULTS_FILE
fi

echo `cat $RESULTS_FILE`
