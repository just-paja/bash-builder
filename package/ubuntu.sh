#!/usr/bin/env bash

PROJECT_VERSION=$(git tag | sort -V | tail -1)
PROJECT_VERSION_PREV=$(git tag | sort -V | tail -2 | head -1)
PROJECT_MAINTAINER=$(git --no-pager show -s --format='%an <%ae>' HEAD)

echo "version: ${PROJECT_VERSION}"
echo "Maintainer: ${PROJECT_MAINTAINER}"

NAME_BASE="bash-builder_${PROJECT_VERSION}"
DIR_ROOT="$(dirname "$(readlink -f "$0")")"
DIR_SRC=$(realpath ${DIR_ROOT}/..)

DIR_TEMP=$(mktemp -d)
DIR_BASE="${DIR_TEMP}/${NAME_BASE}"
DIR_DEBIAN="${DIR_BASE}/DEBIAN"
DIR_BIN="${DIR_BASE}/usr/bin"
DIR_DOC="${DIR_BASE}/usr/share/doc/bash-builder"
DIR_SHARE="${DIR_BASE}/usr/share/bash-builder"

# Copy over bash things
mkdir -p ${DIR_DEBIAN} ${DIR_BIN} ${DIR_DOC} ${DIR_SHARE}
chmod -R 755 ${DIR_TEMP}

cp README.md ${DIR_SHARE}
cp bash-builder ${DIR_SHARE}
cp -R lib ${DIR_SHARE}
cp -R inline ${DIR_SHARE}

# Update Ubuntu package control files
cp -R package/DEBIAN/control/* ${DIR_DEBIAN}
cp -R package/DEBIAN/doc/* ${DIR_DOC}

for file in ${DIR_DEBIAN}/*; do
  sed -i "s/{VERSION}/${PROJECT_VERSION}/g" ${file}
  sed -i "s/{MAINTAINER}/${PROJECT_MAINTAINER}/g" ${file}
done

git log > ${DIR_DOC}/changelog
gzip -n -9 ${DIR_DOC}/changelog
chmod 644 ${DIR_DOC}/changelog*

# Create executable
ln -s ../share/bash-builder/bash-builder ${DIR_BIN}/bash-builder

# Package it
fakeroot dpkg-deb --build ${DIR_BASE}
mv ${DIR_TEMP}/*.deb ./

# Remove temporary files
rm -rf ${DIR_TEMP}

ls ./*.deb
