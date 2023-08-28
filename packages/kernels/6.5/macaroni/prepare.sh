#!/bin/bash
set -ex
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
download_version=${PACKAGE_VERSION}
if [ "${PACKAGE_VERSION}" = "6.5.0" ] ; then
  download_version="6.5"
fi

wget https://cdn.kernel.org/pub/linux/kernel/v${PACKAGE_VERSION:0:1}.x/${KERNEL_TYPE}-${download_version}.tar.xz -O kernel.tar.xz
tar xJf kernel.tar.xz
mv ${KERNEL_TYPE}-${download_version} ${KERNEL_TYPE}
cp -rfv macaroni-$ARCH.config ${KERNEL_TYPE}/.config
cd ${KERNEL_TYPE}
make olddefconfig
