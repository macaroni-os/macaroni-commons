#!/bin/bash
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
mkdir -p output/boot
pushd ${KERNEL_TYPE}

minor=$(echo $RELEASE | cut -d'.' -f 3)
if [ "${minor}" == "" ] ; then
  PACKAGE_VERSION="${PACKAGE_VERSION}.0"
fi

make -j$(nproc --ignore=1) KBUILD_BUILD_VERSION="$PACKAGE_VERSION-Macaroni"

if [[ -L "arch/${ARCH}/boot/bzImage" ]]; then
   cp -rfv $(readlink -f "arch/${ARCH}/boot/bzImage") ../output/boot/"kernel-${KERNEL_PREFIX}-${ARCH}-${PACKAGE_VERSION}-${SUFFIX}"
else
   cp -rfv arch/${ARCH}/boot/bzImage ../output/boot/"kernel-${KERNEL_PREFIX}-${ARCH}-${PACKAGE_VERSION}-${SUFFIX}"
fi
