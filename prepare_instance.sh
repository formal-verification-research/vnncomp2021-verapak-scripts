#!/bin/bash
# four arguments, first is "v1", second is a benchmark category identifier string such as "acasxu", third is path to the .onnx file and fourth is path to .vnnlib file

TOOL_NAME=verapak
VERSION_STRING=v1

CONTAINER="verapak_container"
IMAGE="verapak:latest"

# check arguments
if [ "$#" -ne 4 ]; then
	echo "Expected 4 arguments (got $#): \"$VERSION_STRING\" <category> <model.onnx> <specs.vnnlib>"
	exit 1
fi

if [ "$1" != ${VERSION_STRING} ]; then
	echo "Expected first argument to be the version string '$VERSION_STRING', instead got '$1'"
	exit 1
fi

CATEGORY=$2
ONNX_FILE=$3
VNNLIB_FILE=$4

echo "Preparing $TOOL_NAME for benchmark instance in category '$CATEGORY' with onnx file '$ONNX_FILE' and vnnlib file '$VNNLIB_FILE'"

# Kill any zombie processes
killall -q python
. components/cleanup.sh v1 $CONTAINER

# Check whether the VNNLIB can be processed, and save the type
IFS=$'\n' VNN_PARSED=(`python lib/vnnlib/vnnlib_lib.py -v $VNNLIB_FILE`)
VNNCENTER=`tr -d 'C:[ ]' <<< ${VNN_PARSED[0]}`
VNNRADII=`tr -d 'R:[ ]' <<< ${VNN_PARSED[1]}`
VNNTYPE=${VNN_PARSED[2]/'T:'/''}

echo "VNN Type: $VNNTYPE"
if [ $VNNTYPE == "OTHER" ] || [[ $VNNTYPE != "MINIMAL" && $VNNTYPE != "MAXIMAL" ]]; then
	echo "Cannot handle the given VNNLIB file"
	exit 1 # Skip this one
fi

VNNNUM=${VNN_PARSED[3]/'N:'/''}

# Convert ONNX to TF
. components/convert_onnx.sh v1 $ONNX_FILE out/net_tf.pb

# Wrangle the graph to have compatible nodes
echo "Wrangle net_tf.pb -> __net_tf.pb"
if [ $VNNTYPE == 2 ]; then
	. components/wrangle.sh v1 out/net_tf.pb out/__net_tf.pb True # Negate it so that it does minimal instead of maximal
else
	. components/wrangle.sh v1 out/net_tf.pb out/__net_tf.pb
fi


# Generate Config file
IFS=$'\n' PER_BENCHMARK=(`python lib/per_benchmark.py benchmarks.conf $CATEGORY $VNNRADII`)

INPUT_NODE=${PER_BENCHMARK[5]}
OUTPUT_NODE=${PER_BENCHMARK[6]}

# Find unspecified nodes
if [ "$INPUT_NODE" == "" ] ; then
	INPUT_NODE=`graph_wrangler parse_nodes.py --disallow_prompt_user --input out/net_tf.pb`
fi
if [ "$OUTPUT_NODE" == "" ] ; then
	OUTPUT_NODE=`graph_wrangler parse_nodes.py --disallow_prompt_user --output out/net_tf.pb`
fi

echo "Input $INPUT_NODE, Output $OUTPUT_NODE"

LABELS_PATH=${PER_BENCHMARK[5]}
CLASS_AVG_PATH=${PER_BENCHMARK[6]}

# Generate unspecified protocol buffers
if [ "$LABELS_PATH" == "" ] ; then
	OUTPUT_SHAPE=`graph_wrangler get_node_shape.py out/net_tf.pb $OUTPUT_NODE | tr -cd [:print:]`
	. components/generate_labels.sh v1 out/labels.pb $OUTPUT_SHAPE $VNNNUM
	LABELS_PATH="out/labels.pb"
fi
if [ "$CLASS_AVG_PATH" == "" ] ; then
	if [[ "${PER_BENCHMARK[2]}" == "intellifeature" || "${PER_BENCHMARK[3]}" == "intellifeature" ]] ; then
		echo "Must have a Class Averages .pb file in order to use Intellifeature"
		exit 1
	else
		CLASS_AVG_PATH=$'/'
	fi
fi


# Generate Initial Activation Point
INPUT_SHAPE=`graph_wrangler get_node_shape.py out/net_tf.pb $INPUT_NODE`
INPUT_SHAPE=${INPUT_SHAPE//'?'/1}
pb_creator --shape="${INPUT_SHAPE//[$'\t\r\n ']}" --value="$VNNCENTER" --output="out/initial_activation_point.pb"
INITIAL_POINT="out/initial_activation_point.pb"


# Write config file
cat > out/verapak.conf <<-END
# Output Directory
out/

# Graph
out/__net_tf.pb
 # Input Node <string>
$INPUT_NODE
 # Output Node <string>
$OUTPUT_NODE
 # Verification Radi(us/i) <float> (applied to all dims) or <float[]> (one per dim)
$VNNRADII
 # Granularity <float> (applied to all dims) or <float[]> (one per dim)
${PER_BENCHMARK[4]}

# Protocol Buffers
 # Initial Activation Point <string : filepath>
$INITIAL_POINT
 # Label <string : filepath>
$LABELS_PATH
 # Class Averages <string : filepath> (Only required when using Intellifeature : Use a single / to denote no value)
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
 # Label Layer <string>
y_label
 # Gradient Layer <string>
gradient_out
END



exit 0
