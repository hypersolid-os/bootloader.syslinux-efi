#!/usr/bin/env bash

set -e

# basedir
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKINGDIR="$(pwd)"
CONTAINER_NAME="bootloader-syslinux-efi"

# create environment
sudo podman build \
    -t ${CONTAINER_NAME} \
    --no-cache \
    . \
&& {
    echo "build environment ready"
} || {
    echo "cannot create build environment"
    exit 1
}

# container already exists ?
sudo podman container rm ${CONTAINER_NAME}-env && {
    echo "existing build environment removed"
} || {
    echo "cannot remove build environment"
}

# create image
sudo podman run \
    --privileged=true \
    --volume /dev:/dev \
    --name ${CONTAINER_NAME}-env \
    --tty \
    --interactive \
    --volume ${BASEDIR}/dist:/tmp/dist \
    --rm \
    ${CONTAINER_NAME} \
&& {
    echo "image created"
} || {
    echo "ERROR: image creation failed"
    exit 3
}