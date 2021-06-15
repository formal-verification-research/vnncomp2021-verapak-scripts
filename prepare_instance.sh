#!/bin/bash
# four arguments, first is "v1", second is a benchmark category identifier string such as "acasxu", third is path to the .onnx file and fourth is path to .vnnlib file

TOOL_NAME=verapak
VERSION_STRING=v1

# check arguments
if [ "$#" -ne 4 ]; then
	echo "Expected four arguments (got $#): '$VERSION_STRING' (version string), benchmark_category, onnx_file, vnnlib_file"
	exit 1
fi

if [ "$1" != ${VERSION_STRING} ]; then
	echo "Expected first argument (version string) '$VERSION_STRING', got '$1'"
	exit 1
fi

CATEGORY=$2
ONNX_FILE=$3
VNNLIB_FILE=$4

echo "Preparing $TOOL_NAME for benchmark instance in category '$CATEGORY' with onnx file '$ONNX_FILE' and vnnlib file '$VNNLIB_FILE'"

# Kill any zombie processes
killall -q python

# Check whether the VNNLIB can be processed, and save the type
IFS=$'\n' VNN_PARSED=(`python vnnlib/vnnlib_lib.py -v $VNNLIB_FILE`)
VNNCENTER=`tr -d 'C:[ ]' <<< ${VNN_PARSED[0]}`
VNNRADII=`tr -d 'R:[ ]' <<< ${VNN_PARSED[1]}`
VNNTYPE=${VNN_PARSED[2]/'T:'/''}

echo "VNN Type: $VNNTYPE"
if [ $VNNTYPE == "OTHER" ] || [[ $VNNTYPE != "MINIMAL" && $VNNTYPE != "MAXIMAL" ]]; then
	echo "Cannot handle the given VNNLIB file"
	exit 1 # Skip this one
fi

# Convert ONNX to TF
onnx-tf convert -i $ONNX_FILE -o ${ONNX_FILE}_tf

# Wrangle the graph to have compatible nodes
if [ $VNNTYPE == 2 ]; then
	python GraphWrangler/main.py ${ONNX_FILE}_tf ${ONNX_FILE}_tf.pb True True  # Negate it so that it does minimal instead of maximal
else
	python GraphWrangler/main.py ${ONNX_FILE}_tf ${ONNX_FILE}_tf.pb True False
fi


# Generate Config file
IFS=$'\n' PER_BENCHMARK=(`python per_benchmark.py benchmarks.conf $CATEGORY $VNNRADII`)

INPUT_NODE=${PER_BENCHMARK[5]}
OUTPUT_NODE=${PER_BENCHMARK[6]}

# Find unspecified nodes
if [[ "$INPUT_NODE" == "" || "$OUTPUT_NODE" == "" ]] ; then
	IFS=$'\n' NODES_PARSED=(`python GraphWrangler/parse_nodes.py --disallow_prompt_user ${ONNX_FILE}_tf`)
fi

if [ "$INPUT_NODE" == "" ] ; then
	INPUT_NODE=${NODES_PARSED[0]}
fi
if [ "$OUTPUT_NODE" == "" ] ; then
	OUTPUT_NODE=${NODES_PARSED[1]}
fi

LABELS_PATH=${PER_BENCHMARK[5]}
CLASS_AVG_PATH=${PER_BENCHMARK[6]}

# Generate unspecified protocol buffers
if [ "$LABELS_PATH" == "" ] ; then

fi
if [ "$CLASS_AVG_PATH" == "" ] ; then

fi


cat > verapak.conf <<-END
# Output Directory
/out

# Graph
${ONNX_FILE}_tf.pb
 # Input Node <string>
${NODES_PARSED[0]}
 # Output Node <string>
${NODES_PARSED[1]}
 # Initial Activation Point <float[]>
$VNNCENTER
 # Verification Radi(us/i) <float> (applied to all dims) or <float[]> (one per dim)
$VNNRADII
 # Granularity <float> (applied to all dims) or <float[]> (one per dim)
${PER_BENCHMARK[4]}

# Protocol Buffers
 # Label <string : filepath>
$LABELS_PATH
 # Class Averages <string : filepath>
$CLASS_AVG_PATH

# Optimization
 # Number of Threads <int>
48
 # Number of Abstractions <int>
${PER_BENCHMARK[0]}
 # FGSM Balance Factor <float>
${PER_BENCHMARK[1]}
 # Modified FGSM Dimension Selection <string in ["intellifeature", "gradient_based"]>
${PER_BENCHMARK[2]}
 # Refinement Dimension Selection <string in ["intellifeature", "gradient_based", "random", "largest_first"]>
${PER_BENCHMARK[3]}

# Other
 # Label Layer
y_layer
 # Gradient Layer
gradient_out
END



exit 0
