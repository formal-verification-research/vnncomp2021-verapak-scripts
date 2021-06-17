# VNNCOMP2021 Scripts for Verapak

All three scripts are provided, as specified in the rules for VNNCOMP2021.

These include:
### `install_tool.sh`
#### Parameters
 - `<Version Number>` : Must be exactly `v1`

#### End result
 - Installs required dependencies
 - Builds a Docker image to `verapak:latest`

### `prepare_instance.sh`
#### Parameters
 - `<Version Number>` : Must be exactly `v1`
 - `<Type Shortname>` : Shortname of the type (e.g. cifar10 or mnist)
 - `<ONNX File>` : Filepath to the ONNX-format model
 - `<VNNLIB File>` : Filepath to the VNNLIB specification for what is a valid adversarial example

#### End result
 - Kills all python processes (to prevent zombie processes from building up)
 - Kills and removes any Docker containers named `verapak_container`
 - `<ONNX File>` is converted to Tensorflow, located at `<ONNX File>_tf.pb`
 - `<ONNX File>_tf.pb` is made compatible with Verapak by adding nodes and saving to `__<ONNX File>_tf.pb`
 - Retrieves settings from `./benchmarks.conf` with the specified `<Type Shortname>` (grabs `__default__` if none match) and:
    - Tries to guess input/output nodes if not given
    - Generates `./<Type Shortname>_labels.pb` if not given (even if the file already exists)
    - Throws an error if Intellifeature is used, and a path to class averages was not given
 - Generates and writes the initial activation point protobuf into `./<Type Shortname>_init.pb`
 - Writes running parameters to `./verapak.conf`

#### Simply
 - Kills all python processes
 - Removes Docker container named `verapak_container`
 - Writes files at `<ONNX File>_tf.pb`, `__<ONNX File>_tf.pb`, `./<Type Shortname>_init.pb>`, `./verapak.conf`, and sometimes `./<Type Shortname>_labels.pb`

### `run_instance.sh`
#### Parameters
 - `<Version Number>` : Must be exactly `v1`
 - `<Type Shortname>` : Shortname of the type (e.g. cifar10 or mnist) _-- **Currently** has no effect_
 - `<ONNX File>` : Filepath to the ONNX-format model _-- **Currently** has no effect_
 - `<VNNLIB File>` : Filepath to the VNNLIB specification for what is a valid adversarial example _-- **Currently** has no effect_
 - `<Results File>` : The file to write the result to
 - `<Timeout (s)>` : The timeout (in seconds)

#### End result
 - Runs Verapak (`verapak:latest`) with the parameters specified in `./verapak.conf` (plus the flags `--terminate_on_counterexample=true` and [effectively] `--root_dir=$PWD`) inside of a Docker container named `verapak_container`
 - Uses a temporary file `./~timeout` on timeout
 - Writes output to `<Results File>`
