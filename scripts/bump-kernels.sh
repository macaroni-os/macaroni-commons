#!/bin/bash

BRANCH=$(echo $RELEASE | sed -e 's/[.][0-9]*$//g')

main () {

  if [ -z "$RELEASE" ] ; then
    echo "Missing new kernel version"
    return 1
  fi

  has_lts=$(ls packages/kernels/${BRANCH}/ | grep lts  | wc -l)

  if [ $has_lts -eq 1 ] ; then
    prev_version=$(yq r packages/kernels/${BRANCH}/macaroni-lts/definition.yaml 'version')
    kerneldir=macaroni-lts
  else
    prev_version=$(yq r packages/kernels/${BRANCH}/macaroni/definition.yaml 'version')
    kerneldir=macaroni
  fi

  files=(
    sources/definition.yaml
    minimal/definition.yaml
    modules/definition.yaml
    definition.yaml
  )

  for i in ${files[@]} ; do
    yq w -i packages/kernels/${BRANCH}/${kerneldir}/${i} 'version' $RELEASE
    yq w -i packages/kernels/${BRANCH}/${kerneldir}/${i} 'labels."package.version"' $RELEASE
  done

  # TODO: check a better solution
  sed -i -e "s|${prev_version}|$RELEASE|g" packages/kernels/initramfs/collection.yaml

  return 0
}

main $@
exit $?
