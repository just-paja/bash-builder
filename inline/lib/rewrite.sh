#!/usr/bin/env bash

function escapeName {
  echo $1 | sed -e 's/[]\/$*.^|[]/\\&/g'
}

function escapeValue {
  echo $1 | sed -e 's/[\/&]/\\&/g'
}

function replace_vars {
  infile=$1
  replace=(${*:2})
  IFS=" "

  while read -r line; do
    for var in ${replace[@]}; do
      varName=$(escapeName "${var}")
      varValue=$(escapeValue "${!var}")
      line=$(echo "${line}" | sed -e "s/\${${varName}}/${varValue}/g")
    done

    echo "${line}"
  done < "${infile}"

  unset IFS
}


function cp_rewrite {
  infile=$1
  outfile=$2
  replace=${*:3}

  echo ":: Configure $2"
  replace_vars $1 $replace > $2
}

export -f replace_vars
export -f cp_rewrite
