#!/bin/sh
set -e -x

cd "$(dirname "$(readlink -f "$0")")"

WARDIR="$1"
TAG="$2"

[ "$TAG" ] || TAG="appl:latest"

echo "Create $TAG from '$PWD' and '$WARDIR'"
[ "$http_proxy" ] && echo "http_proxy=$http_proxy"

[ -r "$WARDIR/mgmt.war" ] || exit 1
[ -r "prepare-in-run.sh" ] || exit 2

[ -r ".git" ] \
 && HASHARG="--build-arg GIT_COMMIT=$(git describe --always --abbrev=1000)"

podman build \
 --tag $TAG \
 --file Containerfile.run \
 --squash \
 --volume "$PWD":/build:ro \
 --volume "$WARDIR":/wars:ro \
 $HASHARG \
 .
