#!/usr/bin/env bash

export ARCHIVE_MARK_TEMPLATE="###--[:archive:{type}:{path}:]--"


###
# Get simplified file type used to determine if it is packed into an
# archive or packed as text script.
#
# @param $1 path File path
# @returns string (ascii|binary)
###
function get_file_type {
  path="$1"
  info=$(file -b --mime-type "${path}" | grep "text/" | wc -l)

  if [ "$?" != "0" ]; then
    return $?
  fi

  type="binary"

  if [ "$info" -gt 0 ]; then
    type="ascii"
  fi

  echo ${type}
}


###
# Create an archive mark from the template. This will be used to match
# all inlined files inside the archive
#
# @param $1 type Archive type. It can be ascii or actual archive type
# @param $2 path Path relative to the script
# @returns string
###
function get_archive_mark {
  type="$1"
  path="$2"

  mark="${ARCHIVE_MARK_TEMPLATE/\{type\}/${type}}"
  mark="${mark/\{path\}/${path}}"

  echo ${mark}
  return $?
}

###
# Separate ASCII files from binary and create directory inline-able
# files that will be processed by the build
#
# @param $1 Path to the target directory
# @param $2, $3, ... Source directory
# @returns void
###
function create_inline_source {
  target="$1"
  sources="${@:2}"

  DIR_RAW="${target}/raw"
  DIR_BINARY="${target}/binary"

  FILE_PACKAGE="${DIR_RAW}/package.tar"
  FILE_PACKAGE_TEMP="${target}/package.tar"

  run_task mkdir -p "${DIR_RAW}" "${DIR_BINARY}"

  for src in $sources; do
    if [ -d ${src} ]; then
      cp -R ${src}/* "${DIR_BINARY}"
    fi
  done

  files=$(find ${DIR_BINARY} -type f)

  for file in $files; do
    type=$(get_file_type "${file}")

    if [ "${type}" == "ascii" ]; then
      dest=${file/${DIR_BINARY}/${DIR_RAW}}
      run_task mkdir -p $(dirname ${dest})
      run_task mv ${file} ${dest}
    fi
  done

  remaining=$(find ${DIR_BINARY} -type f | wc -l)

  if [ "${remaining}" -gt 0 ]; then
    tar -C ${DIR_BINARY} -cf ${FILE_PACKAGE_TEMP} .
    run_task mv ${FILE_PACKAGE_TEMP} ${FILE_PACKAGE}
  fi

  run_task mv ${DIR_RAW}/* ${target}
  run_task rm -Rf ${DIR_BINARY} ${DIR_RAW}

  return $?
}


export -f get_file_type
export -f get_archive_mark
export -f create_inline_source
