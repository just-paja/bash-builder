#!/usr/bin/env bash

PROJECT_VERSION=$(git tag | sort -V | tail -1)
PROJECT_VERSION_PREV=$(git tag | sort -V | tail -2 | head -1)
PROJECT_MAINTAINER=$(git --no-pager show -s --format='%an <%ae>' HEAD)

echo "version: ${PROJECT_VERSION}"
echo "Maintainer: ${PROJECT_MAINTAINER}"

DIR_ROOT="$(dirname "$(readlink -f "$0")")"
DIR_SRC=$(realpath ${DIR_ROOT}/..)

DIR_TEMP=$(mktemp -d)
DIR_DEBIAN="${DIR_TEMP}/DEBIAN"
DIR_BIN="${DIR_TEMP}/usr/bin"
DIR_DOC="${DIR_TEMP}/usr/share/doc/bash-builder"
DIR_SHARE="${DIR_TEMP}/usr/share/bash-builder"

# Copy over bash things
mkdir -p ${DIR_DEBIAN} ${DIR_BIN} ${DIR_DOC} ${DIR_SHARE}
chmod -R 755 ${DIR_TEMP}

cp README.md ${DIR_SHARE}
cp bash-builder ${DIR_SHARE}
cp -R lib ${DIR_SHARE}

# Update Ubuntu package control files
cp -R package/DEBIAN/control/* ${DIR_DEBIAN}
cp -R package/DEBIAN/doc/* ${DIR_DOC}

for file in ${DIR_DEBIAN}/*; do
  sed -i "s/{VERSION}/${PROJECT_VERSION}/g" ${file}
  sed -i "s/{MAINTAINER}/${PROJECT_MAINTAINER}/g" ${file}
done

git log > ${DIR_DOC}/changelog
gzip -9 ${DIR_DOC}/changelog
chmod 644 ${DIR_DOC}/changelog.gz

# Create executable
ln -s ../share/bash-builder/bash-builder ${DIR_BIN}/bash-builder

chown -R root:root ${DIR_SHARE}
dpkg-deb --build ${DIR_TEMP}

echo ${DIR_TEMP}
rm -rf ${DIR_TEMP}
