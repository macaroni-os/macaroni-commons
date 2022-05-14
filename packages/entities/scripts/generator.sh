#!/bin/bash
# Author: Daniele Rondina, geaaru@funtoo.org
# Description: This script generate the specs-dir for entities
#              to use the merge command.
#
# Requires: yq, jq

TARGET_DIR=${TARGET_DIR:-./entities}

GROUPS_FILE="${GROUPS_FILE:-groups.yaml}"
USERS_FILE="${USERS_FILE:-users.yaml}"
GRP_DYNAMIC_FILE="${GRP_DYNAMIC_FILE:-groups-dynamic.yaml}"
USERS_DYNAMIC_FILE="${USERS_DYNAMIC_FILE:-users-dynamic.yaml}"

generate_user() {
  local usr=$1
  local data=$2
  local dynamic=${3:-""}
  local uf="${TARGET_DIR}/users/entity_user_${usr}.yaml"

  echo "Creating user ${usr}..."

  echo "
kind: user
username: ${usr}
" > ${uf}

  if [ -n "${dynamic}" ] ; then
    echo "uid: -1" >> ${uf}
  fi

  echo "${data}" | yq r - -P > /tmp/entity.yaml
  # Remove shadow section available in users.yaml definition
  yq d -i /tmp/entity.yaml 'shadow' || true
  yq m -i /tmp/entity.yaml ${uf}
  rm ${uf}
  mv /tmp/entity.yaml ${uf}

  local shadow=$(echo ${data} | jq '.shadow // null')
  local sf="${TARGET_DIR}/shadows/entity_shadow_${usr}.yaml"
  if [ "${shadow}" != "null" ] ; then
    # POST: creating shadow file.

    pass="$(echo ${shadow} | jq '.password // null' -r)"
    if [ "${password}" != "null" ] ; then
      echo "
kind: shadow
username: ${usr}
" > ${sf}
    else
      echo "
kind: shadow
username: ${usr}
password: \"\"
" > ${sf}
    fi

    echo "${shadow}" | yq r - -P > /tmp/entity.yaml

    yq m -i /tmp/entity.yaml ${sf}
    rm ${sf}
    mv /tmp/entity.yaml ${sf}
  fi

  return 0
}

generate_group() {
  local grp=$1
  local data=$2
  local dynamic=${3:-""}

  gid=$(echo ${data} | jq '.gid' -r)
  password=$(echo ${data} | jq '.password' -r)
  users=$(echo ${data} | jq '.users // ""' -r)
  local f="${TARGET_DIR}/groups/entity_group_${grp}.yaml"

  echo "
kind: group
group_name: ${grp}
gid: ${gid}
password: "${password}"
" > ${f}

  if [ -n "${dynamic}" ] ; then
    echo "gid: -1" >> ${f}
  fi

  if [ -n "${users}" ] ; then
    yq w -i ${f} "users" "${users}"
  fi

  local shadow=$(echo ${data} | jq '.shadow // null')
  local sf="${TARGET_DIR}/shadows/entity_shadow_${grp}.yaml"
  if [ "${shadow}" != "null" ] ; then
    # POST: creating shadow file.

    pass="$(echo ${shadow} | jq .password -r)"
    if [ -n "${password}" ] ; then
      echo "
kind: shadow
username: ${grp}
" > ${sf}
    else
      echo "
kind: shadow
username: ${grp}
password: \"\"
" > ${sf}
    fi

    echo "${shadow}" | yq r - -P > /tmp/entity.yaml

    yq m -i /tmp/entity.yaml ${sf}
    rm ${sf}
    mv /tmp/entity.yaml ${sf}
  fi

  local user=$(echo ${data} | jq '.user // null')
  if [ "${user}" != "null" ] ; then
    generate_user "${grp}" "${user}"
  fi

  local gshadow=$(echo ${data} | jq '.gshadow // null')
  local gf="${TARGET_DIR}/gshadows/entity_gshadow_${grp}.yaml"
  if [ "${gshadow}" != "null" ] ; then
    # POST: creating gshadow file
    echo "
kind: gshadow
name: ${grp}
" > ${gf}

    echo "${gshadow}" | yq r - -P > /tmp/entity.yaml
    yq m -i /tmp/entity.yaml ${gf}
    rm ${gf}
    mv /tmp/entity.yaml ${gf}
  fi

  return 0
}

main () {
  local ngrps=0
  local i=0

  mkdir -p ${TARGET_DIR}/groups || true
  mkdir -p ${TARGET_DIR}/shadows || true
  mkdir -p ${TARGET_DIR}/users || true
  mkdir -p ${TARGET_DIR}/gshadows || true

  # Generate groups
  groups=$(yq r ${GROUPS_FILE} -j | jq '.groups | keys | .[]' -r)
  if [ -n "${groups}" ] ; then
    for i in ${groups} ; do
      echo "Creating group ${i}..."
      grpdata=$(yq r ${GROUPS_FILE} -j | jq ".groups[\"${i}\"]" -c)
      generate_group "${i}" "${grpdata}"
    done
  fi

  # Generate users
  users=$(yq r ${USERS_FILE} -j | jq '.users | keys | .[]' -r)
  if [ -n "${users}" ] ; then
    for i in ${users} ; do
      userdata=$(yq r ${USERS_FILE} -j | jq ".users[\"${i}\"]")
      generate_user "${i}" "${userdata}"
    done
  fi

  # Generate dynamic groups
  groups=$(yq r ${GRP_DYNAMIC_FILE} -j | jq '.groups | keys | .[]' -r)
  if [ -n "${groups}" ] ; then
    for i in ${groups} ; do
      grpdata=$(yq r ${GRP_DYNAMIC_FILE} -j | jq ".groups[\"${i}\"]")
      generate_group "${i}" "${grpdata}" "1"
    done
  fi

  # Generate dynamic users
  users=$(yq r ${USERS_DYNAMIC_FILE} -j | jq '.users | keys | .[]' -r)
  if [ -n "${users}" ] ; then
    for i in ${users} ; do
      userdata=$(yq r ${USERS_DYNAMIC_FILE} -j | jq ".users[\"${i}\"]")
      generate_user "${i}" "${userdata}" "1"
    done
  fi

  return 0
}

main $@
exit $?
