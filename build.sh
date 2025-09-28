#!/usr/bin/env bash

set -e

# sys partition size provided ?
if [ -z "${1}" ]; then
    echo "system partition size not provided - using default 1G setting"
    PART_SYS_SIZE=1000
else
    echo "using system partition size of ${1}MB"
    PART_SYS_SIZE="${1}"
fi

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
    --env "PART_SYS_SIZE=${PART_SYS_SIZE}" \
    --env "PART_LAYOUT=${2}" \
    --rm \
    ${CONTAINER_NAME} \
&& {
    echo "image created"
} || {
    echo "ERROR: image creation failed"
    exit 3
}