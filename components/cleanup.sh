#!/bin/bash

TOOL_NAME=verapak
VERSION_STRING=v1

# check arguments
if [ "$1" != ${VERSION_STRING} ]; then
	echo "Expected first argument to be the version string '$VERSION_STRING', instead got '$1'" 1>&2
	exit 1
fi

if [[ "$#" -ne 2 ]]; then
	echo "Expected 2 arguments (got $#): \"$VERSION_STRING\" <container_name>" 1>&2
	exit 1
fi

CONTAINER=$2

docker stop $CONTAINER > /dev/null 2>&1
docker kill $CONTAINER > /dev/null 2>&1
docker container rm $CONTAINER > /dev/null 2>&1
