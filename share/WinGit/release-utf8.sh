#!/bin/bash

maketag=0
if [ "$1" = "--tag" ]; then
    maketag=1
    shift
fi

if [ $# -lt 1 ]; then
    echo 'Usage:'
    echo '   ./release-utf8.sh [--tag] <version>'
    exit
fi

# Curl Http Proxy
export http_proxy='127.0.0.1:9999'
echo " "
echo "Set CURL HTTP Proxy [$http_proxy]."
echo " "
sleep 1

version=$1
build=$(date +%Y%m%d)
fullversion=$version-msysgit-utf8-$build

echo $fullversion>/git/version

if [ $maketag -eq 1 ]; then
    pushd /git >nul
    git tag -d v$fullversion >nul 2>nul
    git tag    v$fullversion
    cd /
    git tag -d Git-$fullversion >nul 2>nul
    git tag    Git-$fullversion
    popd >nul
fi

# Copy libiconv-2.dll
cp /mingw/bin/libiconv-2.dll /libexec/git-core/

./release.sh -f $fullversion

# Delete version file
rm -f /git/version

# Move installer
installer=\"$(tail -n 1 /tmp/install.out)\"
dest=\"..\\..\\..\\Git-$fullversion.exe\"
echo Move installer to $dest ...
cmd /c "move /y $installer $dest"
