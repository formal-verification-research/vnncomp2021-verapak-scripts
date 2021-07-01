#!/bin/bash

TOOL_NAME=verapak
VERSION_STRING=v1

# check arguments
if [ "$1" != ${VERSION_STRING} ]; then
	echo "Expected first argument to be the version string '$VERSION_STRING', instead got '$1'"
	exit 1
fi

if [[ "$#" -ne 2 ]]; then
	echo "Expected 2 arguments (got $#): \"$VERSION_STRING\" <container_name>"
	exit 1
fi

CONTAINER=$2

docker stop $CONTAINER
docker kill $CONTAINER
docker container rm $CONTAINER
