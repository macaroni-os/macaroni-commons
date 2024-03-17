#!/bin/bash
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
mkdir -p output/boot
pushd ${KERNEL_TYPE}

make -j$(nproc --ignore=1) KBUILD_BUILD_VERSION="$PACKAGE_VERSION-Macaroni"

kernel_version="${PACKAGE_VERSION}-zen1"

if [[ -L "arch/${ARCH}/boot/bzImage" ]]; then
   cp -rfv $(readlink -f "arch/${ARCH}/boot/bzImage") ../output/boot/"kernel-${KERNEL_PREFIX}-${ARCH}-${kernel_version}-${SUFFIX}"
else
   cp -rfv arch/${ARCH}/boot/bzImage ../output/boot/"kernel-${KERNEL_PREFIX}-${ARCH}-${kernel_version}-${SUFFIX}"
fi
