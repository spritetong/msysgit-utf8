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

./release.sh -f $version-msysgit-utf8

installer=\"$(tail -n 1 /tmp/install.out)\"
dest=\"..\\..\\..\\Git-$version-msysgit-utf8.exe\"
echo Move installer to $dest ...
cmd /c "move /y $installer $dest"
