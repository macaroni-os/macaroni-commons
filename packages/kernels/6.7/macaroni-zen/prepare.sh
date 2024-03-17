#!/bin/bash
set -ex
PACKAGE_VERSION=${PACKAGE_VERSION%\+*}
download_version=${PACKAGE_VERSION}
if [ "${PACKAGE_VERSION}" = "6.7.0" ] ; then
  download_version="6.7"
fi

original_version="${download_version}-zen1"
wget https://github.com/zen-kernel/zen-kernel/archive/refs/tags/v${original_version}.tar.gz -O kernel.tar.gz
tar xzf kernel.tar.gz
mv zen-kernel-${download_version} ${KERNEL_TYPE}
cp -rfv macaroni-zen-$ARCH.config ${KERNEL_TYPE}/.config
cd ${KERNEL_TYPE}
make olddefconfig
