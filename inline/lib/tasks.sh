#!/usr/bin/env bash

ALLOWED_EXIT_CODES=("0")

function is_ok {
  is_ok_result=${1}

  for code in ${ALLOWED_EXIT_CODES[@]}; do
    if [ "${is_ok_result}" == "${code}" ]; then
      echo 'yes'
      return 0
    fi
  done

  echo 'no'
  return 1
}

function run_task {
  run_task_routine "$@"
  run_task_result=$?
  ok=$(is_ok ${run_task_result})

  # Kill the script if it didn't
  if [ "${ok}" != "yes" ]; then
    echo "Task has failed with exit code ${run_task_result}" 1>&2
    echo "${task}" 1>&2
    exit ${run_task_result}
  fi
}

function run_task_routine {
  task=$@
  ${task}
  return $?
}

###
# Run generic task and log its output. Do not care about exit codes
# @params string Command with arguments
###
function log_task_routine {
  FILE_LOG_TMP=$(mktemp)

  # The file will contains only output for this command
  run_task_routine "$@" &> ${FILE_LOG_TMP}
  run_task_routine_result=$?
  ok=$(is_ok ${run_task_routine_result})

  if [ "${FILE_LOG}" == "" ]; then
    echo "Please supply FILE_LOG environment variable pointing to your log" >&2
    exit 1
  fi

  # If command went trough, save its output
  cat ${FILE_LOG_TMP} >> ${FILE_LOG}
  rm ${FILE_LOG_TMP}

  if [ "${ok}" != "yes" ]; then
    cat ${FILE_LOG} >&2
    echo "This log is preserved in ${FILE_LOG}" >&2
    exit ${run_task_routine_result}
  fi

  return ${run_task_routine_result}
}

###
# Run task and log its output, standard edition.
# @params string Command with arguments
###
function log_task {
  ALLOWED_EXIT_CODES=("0")
  log_task_routine "$@"
}

function run_sequence {

  for command in "$@"; do
    echo ">> $(basename $command)"

    ${command}
    run_sequence_result=$?
    ok=$(is_ok ${run_sequence_result})

    if [ "${ok}" != "yes" ]; then
      return ${run_sequence_result}
    fi
  done

  return 0
}

export -f is_ok
export -f log_task_routine
export -f log_task
export -f run_sequence
export -f run_task
export -f run_task_routine
