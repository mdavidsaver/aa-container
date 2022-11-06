# Archiver Appliance Demo Container

Scripts to build an OCI container image with a
standalone EPICS Archiver Applance.

## Build AA into WAR files

```sh
podman run --rm \
 -v $PWD:/build \
 docker.io/library/debian:11 \
 /build/build-wars.sh
```

## Build image

Build container from .war files.

```sh
sudo ./build-run.sh $PWD/wars
```

## Run image

Test run container.

```sh
sudo install -d /var/lib/appl
sudo podman run --rm -ti \
 -v /var/lib/appl:/persist \
 --net host \
 --stop-timeout 600 \
 --shm-size 128m \
 --name appltest \
 epicsarchiverap
```

The directory `/var/lib/appl` should initially be empty.
On first start, it will be populated with default configuration.

Then visit `http://localhost:17665/mgmt/ui/storage.html`.

Trigger a clean shutdown with:

```sh
sudo podman stop appltest
```

The host directory `/var/lib/appl` will be populated
initially with default configuration.

## docker/podman arguments

`--stop-timeout 600` is essential to allow the
ETL process sufficient time to copy from the short term (STS)
RAM disk without data loss.

`--shm-size 128m` is setting the size of the STS RAM disk,
which must be sufficient to hold ~2 hours of data.
See the `Storage` report available through the AA web UI.

`--net host` is a suggested starting point as it requires no additional network configuration.
`--net bridge` is another option which provides more isolation while also passing UDP broadcast traffic,
but requires additional network configuration.

## Customization

For hooks to configure individual containers see [README.persist](README.persist).


## Speeding up image build

Of Debian based images on a Debian host.
Run a http proxy to cache .deb packages.

```sh
# runs specially configured squid
sudo apt-get install squid-deb-proxy
# stop regular (unused) squid
sudo systemctl stop squid
sudo systemctl disable squid
sudo systemctl mask squid
```

```sh
export http_proxy=http://172.16.16.1:8000/
```

`podman` by default passes `$http_proxy` through.
