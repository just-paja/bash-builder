#!/usr/binenv bash

DIR_TMP="/var/tmp/bash-build"
DIR_LIB="${DIR_ROOT}/lib"
DIR_TARGET="${DIR_ROOT}/target"
FILE_ANCHOR=".bash-builder"

function get_root {
  pwd=$(pwd -P 2>/dev/null || command pwd)
  root=${pwd}

  while [ ! -e "${root}/${FILE_ANCHOR}" ]; do
    root=${root%/*}

    if [ "${root}" = "" ]; then
      break;
    fi
  done

  if [ "${root}" == "" ]; then
    root=${pwd}
  fi

  echo ${root}
}

function get_all_project_sources {
  src=$(get_root)
  echo "${src}/projects"

  if [ "${src}" != "${DIR_ROOT}" ]; then
    echo "${DIR_ROOT}/projects"
  fi
}

function get_all_projects {
  src=$(get_all_project_sources)

  for dir in ${src}; do
    find ${dir} -mindepth 1 -maxdepth 1 -type d -printf "%f\n"
  done
}

function find_project_root {
  src=$(get_all_project_sources)
  dest=""

  for dir in ${src}; do
    path="${dir}/$1"

    if [ -d "${path}" ]; then
      dest=${path}
      break
    fi
  done

  if [ "${dest}" != "" ]; then
    echo ${dest}
  fi
}

function get_project_root {
  dest=$(find_project_root "$1")

  if [ "${dest}" == "" ]; then
    echo "Could not find project root" >&2
    exit 2;
  fi

  echo ${dest}
}

function get_project_tmp_dir {
  echo "${DIR_TMP}/${1}"
}

function get_project_target {
  project_root=$(get_project_root "$1")
  root=$(get_root)
  target=$root/target
  . ${project_root}/meta

  if [ ! -e ${target} ]; then
    mkdir ${target}
  fi

  echo "${target}/${1}-${VERSION}.sh"
}

function project_exists {
  find_project_root "$1" | wc -l
}

function project_build {
  project="$1"

  DIR_SRC=$(get_project_root "${project}")
  DIR_REPO=$(get_root)
  DIR_TMP_PROJECT=$(get_project_tmp_dir "${project}")
  DIR_INLINE_GLOBAL="${DIR_ROOT}/inline"
  DIR_INLINE_REPO="${repo}/inline"
  DIR_INLINE_LOCAL="${DIR_SRC}"
  DIR_INLINE_SRC="${DIR_TMP_PROJECT}/inline"

  FILE_INLINED="${DIR_TMP_PROJECT}/inline.tar"
  FILE_TARGET=$(get_project_target "${project}")
  FILE_TASKS="${DIR_LIB}/tasks.sh"
  FILE_UNPACK="${DIR_LIB}/unpack.sh"

  run_task mkdir -p ${DIR_TARGET}
  run_task create_inline_source "${DIR_INLINE_SRC}" "${DIR_INLINE_GLOBAL}" "${DIR_INLINE_REPO}" "${DIR_INLINE_LOCAL}"

  cat ${FILE_TASKS} > ${FILE_TARGET}
  cat ${FILE_UNPACK} >> ${FILE_TARGET}
  echo >> ${FILE_TARGET}

  inlines=$(find ${DIR_INLINE_SRC} -type f)

  for file in ${inlines}; do
    type=$(get_file_type ${file})
    path=${file/${DIR_INLINE_SRC}\//}

    if [ "${type}" == "binary" ]; then
      type=$(file -b --mime-type ${file})
    fi

    echo >> ${FILE_TARGET}
    get_archive_mark "${type}" "${path}" >> ${FILE_TARGET}
    cat ${file} >> ${FILE_TARGET}
  done

  chmod +x ${FILE_TARGET}
}

function project_clean {
  rm -f $(get_project_target "$1")
  project_clean_tmp "$1"
}

function project_clean_tmp {
  rm -Rf $(get_project_tmp_dir "$1")
}

export -f find_project_root
export -f get_root
export -f get_all_project_sources
export -f get_all_projects
export -f get_project_root
export -f get_project_target
export -f get_project_tmp_dir
export -f project_build
export -f project_exists
