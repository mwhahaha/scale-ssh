#!/bin/bash
# blank this if you don't want sudo
SUDO_CMD="sudo"
BUILD_ENGINE="buildah"
CONTAINER="localhost/scale-ssh"

if [ "$BUILD_ENGINE" == "buildah" ]; then
  $SUDO_CMD $BUILD_ENGINE bud -f Dockerfile -t $CONTAINER .
else
  echo "$BUILD_ENGINE is unsupported"
  exit 1
fi
