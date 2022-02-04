#!/usr/bin/env bash

# Script to install algod in all sorts of different ways.
#
# Parameters:
#    -d    : Location where binaries will be installed.
#    -u    : Git repository URL
#    -b    : Git branch
#    -s    : (optional) Git Commit SHA hash

set -e

rootdir=`dirname $0`
pushd $rootdir

BINDIR=""
URL=""
BRANCH=""
SHA=""

while getopts "d:c:u:b:s:" opt; do
  case "$opt" in
    d) BINDIR=$OPTARG; ;;
    u) URL=$OPTARG; ;;
    b) BRANCH=$OPTARG; ;;
    s) SHA=$OPTARG; ;;
  esac
done

echo "Installing algod with options:"
echo "  BINDIR = ${BINDIR}"
echo "  URL = ${URL}"
echo "  BRANCH = ${BRANCH}"
echo "  SHA = ${SHA}"

git clone --single-branch --branch "${BRANCH}" "${URL}"
cd go-algorand
if [ "${SHA}" != "" ]; then
  echo "Checking out ${SHA}"
  git checkout "${SHA}"
fi

git log -n 5

./scripts/configure_dev.sh
patch -p1 < /tmp/reach2.patch
make build
./scripts/dev_install.sh -p $BINDIR

$BINDIR/algod -v
