#!/bin/sh
set -e -x

cd "$(dirname "$(readlink -f "$0")")"

WARDIR="$1"
TAG="$2"

[ "$TAG" ] || TAG="epicsarchiverap:latest"

echo "Create $TAG from '$PWD' and '$WARDIR'"
[ "$http_proxy" ] && echo "http_proxy=$http_proxy"

[ -r "$WARDIR/mgmt.war" ] || exit 1
[ -r "prepare-in-run.sh" ] || exit 2

[ -r ".git" ] \
 && SCRIPT_VER="--build-arg SCRIPT_VER=$(git describe --always --abbrev=1000)"

[ -r "epicsarchiverap/.git" ] \
 && APPL_VER="--build-arg APPL_VER=$(git --git-dir epicsarchiverap/.git describe --always --abbrev=1000)"

podman build \
 --tag $TAG \
 --file Containerfile.run \
 --squash \
 --volume "$PWD":/build:ro \
 --volume "$WARDIR":/wars:ro \
 $SCRIPT_VER $APPL_VER \
 .
