import argparse
import tensorflow as tf
import numpy as np

parser = argparse.ArgumentParser()
parser.add_argument("--shape")
parser.add_argument("--value")
parser.add_argument("--dtype", default="float32")
parser.add_argument("-o", "--output", default="input.pb")

args = parser.parse_args()
print(args)

val = [float(x) for x in args.value.split(',')]
shape = [int(x) for x in args.shape.split(',')]
d = np.float32
if args.dtype == "int32":
    d = np.int32
elif args.dtype == "float64":
    d = np.float64
elif args.dtype == "int64":
    d = np.int64

a = np.array(val, dtype=d)

file_name = args.output
proto = tf.make_tensor_proto(a, dtype=a.dtype, shape=a.shape)
with open(file_name, 'wb') as f:
    f.write(proto.SerializeToString())

