#!/usr/bin/env bash

. ${DIR_HOME}/lib/vars.sh
. ${DIR_HOME}/lib/rewrite.sh

src="${DIR_HOME}/inline/slashtest.txt"
dest=$(mktemp)

echo ${TEST_VAR}

variable="variable"
value="666"
cp_rewrite ${src} ${dest} variable value

cat ${dest}
rm ${dest}

echo "Exiting"
