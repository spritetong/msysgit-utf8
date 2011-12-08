#!/bin/bash

if test $# -lt 1
then
    echo 'Usage:'
    echo '   ./release-utf8.sh <version>'
    exit
fi

version=$1
build=$(date +%Y%m%d)
fullversion=$version-msysgit-utf8-$build

echo $fullversion>/git/version

pushd /git >nul
git tag -d v$fullversion >nul 2>nul
git tag    v$fullversion
cd /
git tag -d Git-$fullversion >nul 2>nul
popd >nul

# Change curl-ca-bundle.crt
cmd /c "..\\..\\cmd\\git-config-win.cmd"

# Copy libiconv-2.dll
cp /mingw/bin/libiconv-2.dll /libexec/git-core/

./release.sh -f $fullversion

# Restore curl-ca-bundle.crt
git checkout -f ../../mingw/bin/curl-ca-bundle.crt

# Delete version file
rm -f /git/version

# Move installer
installer=\"$(tail -n 1 /tmp/install.out)\"
dest=\"..\\..\\..\\Git-$fullversion.exe\"
echo Move installer to $dest ...
cmd /c "move /y $installer $dest"
