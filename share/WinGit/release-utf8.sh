#!/bin/bash

if test $# -lt 2
then
    echo 'Usage:'
    echo '   ./release-utf8.sh <version> <build-number>'
    exit
fi

version=$1
build=$2

pushd /git >nul
git tag -d v$version-msysgit-utf8.$build >nul 2>nul
git tag    v$version-msysgit-utf8.$build
cd /
git tag -d Git-$version-msysgit-utf8 >nul 2>nul
popd >nul

# Change curl-ca-bundle.crt
cmd /c "..\\..\\cmd\\git-config-win.cmd"

./release.sh -f $version-msysgit-utf8

# Restore curl-ca-bundle.crt
git checkout -f ../../mingw/bin/curl-ca-bundle.crt

# Move installer
installer=\"$(tail -n 1 /tmp/install.out)\"
dest=\"..\\..\\..\\Git-$version-msysgit-utf8.exe\"
echo Move installer to $dest ...
cmd /c "move /y $installer $dest"
