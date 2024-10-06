#!/bin/bash
set -ex
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
kernel_version="${PACKAGE_VERSION}-zen1"
mkdir -p /luetbuild/sources/usr/src/
mv ${KERNEL_TYPE} /luetbuild/sources/usr/src/${KERNEL_TYPE}-${kernel_version}-${SUFFIX}
