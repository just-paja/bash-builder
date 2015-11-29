#!/usr/bin/env bash

# This script is not supposed to run alone. It is meant to be injected
# into bash library

export ARCHIVE_MARK_REGEX="\-\-\[:archive:(.+):(.+):\]\-\-"

###
# List all the archived files including their type and path relative
# to the script and line where it starts. Assume that the script ends
# where the file ends or another inlined archive starts
#
# @param $1 Path to the file
# @returns space separated list of line,type,path,endline groups.
###
function list_archive_marks {
  file="$1"
  found=$(grep -anE "${ARCHIVE_MARK_REGEX}" "$file")
  parsed=""

  for mark in $found; do
    line=$(echo ${mark} | cut -d: -f1)
    type=$(echo ${mark} | cut -d: -f4)
    path=$(echo ${mark} | cut -d: -f5)

    if [ "${parsed}" != "" ]; then
      parsed="${parsed}${line}"
    fi

    parsed="${parsed} ${line}:${type}:${path}:"
  done

  echo ${parsed} | xargs
  return $?
}


export SCRIPT_FILE=$(basename "$0")
export SCRIPT_NAME=${SCRIPT_FILE%.*}

export DIR_EXTRACT="/var/tmp/bash-builder/bash/${SCRIPT_NAME}"
export DIR_HOME="${DIR_EXTRACT}/inline"

DIR_INLINE="${DIR_EXTRACT}/inline"
DIR_SCRIPTS="${DIR_HOME}/scripts"
FILE_META="${DIR_HOME}/meta"
FILE_PACK="${DIR_HOME}/package.tar"


if [ -e ${DIR_EXTRACT} ]; then
  run_task rm -rf ${DIR_EXTRACT}
fi

run_task mkdir -p ${DIR_EXTRACT}

marks=$(list_archive_marks $0)

# Unpack all inlined files
for mark in $marks; do
  start=$(echo $mark | cut -d: -f1)
  type=$(echo $mark | cut -d: -f2)
  path=$(echo $mark | cut -d: -f3)
  end=$(echo $mark | cut -d: -f4)

  start=$((start + 1))

  cmd="${start}"

  if [ "${end}" != "" ]; then
    end=$((end - 1))
    cmd="${cmd},${end}"
  else
    cmd="${cmd},$"
  fi

  cmd="${cmd}p"
  run_task mkdir -p $(dirname ${DIR_HOME}/${path})
  run_task sed -n "${cmd}" $0 > "${DIR_HOME}/${path}"

  # TODO: Rewrite into archive lib, so it keeps +x
  if [[ "${path}" == *".sh" ]]; then
    chmod +x ${DIR_HOME}/${path}
  fi
done

if [ -f "${FILE_PACK}" ]; then
  run_task  tar -xf ${FILE_PACK} -C ${DIR_INLINE}
fi

# Import file main var
. ${FILE_META}

if [ -e ${DIR_INLINE}/lib/bash-builder/pre-run-vars.sh ]; then
  . ${DIR_INLINE}/lib/bash-builder/pre-run.sh
fi

# Run the composed script
"${DIR_EXTRACT}/inline/${FILE_MAIN}" $@
exit $?
