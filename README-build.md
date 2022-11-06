# Building epicsarchiverap container image

Neither of these stages need to be run as `root`.
Doing so is only a convience to avoid needing
to move the image into `/root` when running.

## Build host setup

The only requirement is the presence of `podman` (or `docker`),
a `bash` shell, and internet access (or a local copy of the base OS image).

```sh
apt-get install podman
```

or

```sh
dnf install podman
```

## Build AA into WAR files

Build source in `epicsarchiverap/` into binaries in `wars/`.

```sh
podman run --rm \
 -v $PWD:/build \
 docker.io/library/debian:11 \
 /build/build-wars.sh
```

## Build image

Build container image from `.war` files.

```sh
sudo ./build-run.sh $PWD/wars
```

The resulting image is named `epicsarchiverap:latest`.
Additional tags may be added.  eg.

```sh
sudo podman tag epicsarchiverap:latest epicsarchiverap:$(date '+%Y%m%d')
```
