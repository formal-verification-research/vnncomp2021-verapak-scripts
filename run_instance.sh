#!/bin/bash
# six arguments, first is "v1", second is a benchmark category itentifier string such as "acasxu", third is path to the .onnx file, fourth is path to .vnnlib file, fifth is a path to the results file, and sixth is a timeout in seconds.

TOOL_NAME=verapak
VERSION_STRING=v1

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

# run the tool to produce the results file
#python3 -m agen.randgen "$ONNX_FILE" "$VNNLIB_FILE" "$RESULTS_FILE"

# Read parameters from file
readarray -t parameters <<< `grep -v "^[[:space:]]*#" verapak.conf | grep -v "^[[:space:]]*$"`

# Run the tool
result=`~/ARFramework/tensorflow/bin/tensorflow/ARFramework/ARFramework_main \
	--root_dir="$PWD" \
	--output_dir="${parameters[0]}" \
	--graph="${parameters[1]}" \
	--input_layer="${parameters[2]}" \
	--output_layer="${parameters[3]}" \
	--initial_activation="${parameters[4]}" \
	--verification_radius="${parameters[5]}" \
	--granularity="${parameters[6]}" \
	--label_proto="${parameters[7]}" \
	--class_averages="${parameters[8]}" \
        --num_threads="${parameters[9]}" \
	--num_abstractions="${parameters[10]}" \
	--fgsm_balance_factor="${parameters[11]}" \
	--modified_fgsm_dim_selection="${parameters[12]}" \
	--refinement_dim_selection="${parameters[13]}" \
	--label_layer="${parameters[14]}" \
	--gradient_layer="${parameters[15]}" \
	`
echo $result

# Write results file
echo "RESULT" > $RESULTS_FILE
