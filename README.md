# Archiver Appliance Demo Container

Source for an OCI container image with a standalone EPICS Archiver Appliance (aka. "AA").

The images produced are intended those new to AA and/or to Linux containers.
Some assumptions specific to small to medium sized installations are made.
(eg. no support for multi-host clusters)

See:

- https://github.com/archiver-appliance/epicsarchiverap
- https://epicsarchiver.readthedocs.io/en/latest/index.html

## Important Caveats

- Intended for small to medium sized installations.
  - No support for clusters.
  - Configuration stored in a single SQLite database file instead of mysql/mariadb engine.
  - Configuration __must__ not be on network storage!
- `/persist/conf/appliance.xml` __must__ be manually edited!

## Current Status

Pre-built images are not currently published.
Each site/user must be built manually an `epicsarchiverap` image.

See [README-build.md](README-build.md) and/or [container.yml](.github/workflows/container.yml).

## Getting Started

The following assumes a "simple" layout, where all AA related
files are stored under `/persist` in the container.

For simplicity, host networking (`--net host`) is used.
Those familiar with `podman`/`docker` may wish to investigate
alternative like `bridge` which provide more isolation, but
which also require additional site specific configuration.

### Example Host filesystem layout

Create an empty directory writable by UID 1000 in the container.

```sh
podman unshare install -d -o 1000 -g 1000 persist
```

## Host Preparation

Install `podman`

```sh
apt-get install podman
```

or

```sh
dnf install podman
```

## Build image

```sh
git clone https://github.com/mdavidsaver/aa-container
cd aa-container
podman build -t epicsarchiverap .
```

On success, the `epicsarchiverap:latest` tag will appear in: `podman image list`.

### First run

Prepare a host directory to mount as `/persist` within the container.

```sh
podman unshare install -d -o 1000 -g 1000 persist
```

Note: For later cleanup, this directory can be removed with `podman unshare rm -rf persist`.

```sh
podman run --rm \
 -v "$PWD"/persist:/persist \
 --net host \
 --hostname $HOSTNAME \
 --env APP_PORT=17665 \
 --env ARCHAPPL_MYIDENTITY=archappl0 \
 epicsarchiverap init
```

On start, `"$PWD"/persist` will be populated with with any missing configuration.
`init` will then exit without running the archiver.

Note: `--env APP_PORT=17665` or `--env ARCHAPPL_MYIDENTITY=archappl0` are defaults, and may be omitted.

Note: The AA service requires that the hostname must match the hostname
      which appears in the `appliances.xml` file.
      Thus `--net host` is followed by `--hostname $HOSTNAME`.

Note: when running with `--net host` the container hostname must match the host.
      Thus `--hostname $HOSTNAME`

## Running

```sh
podman run --rm \
 --name archappl \
 -v "$PWD"/persist:/persist \
 --stop-timeout=60 \
 --net host \
 --hostname $HOSTNAME \
 epicsarchiverap run
```

This will run until interrupted with `SIGINT` or `SIGTERM`,
or alternativly by running: `podman stop --name archappl --stop-timeout=60`.

### Test

Visit `http://localhost:17665/mgmt/ui/index.html`.

Where `localhost` should be substitued with the hostname.

## Customization

Most static configuration is through the directory bound as [`/persist`](README-persist.md).
This is `/var/lib/appl` in the examples above.

### Separate data storage

eg. To place the Long Term Storage (LTS) data in a different location
add the following to all `podman run` and `podman create` after
the bind for `/persist`.

```
-v /var/lib/lts_data:/persist/lts
```

### JVM Options

Add `-e CATALINA_OPTS=...` when running.

```
CATALINA_OPTS=-Djava.awt.headless=true -Xmx128m
```

### EPICS Channel Access Options

Add eg. `-e EPICS_CA_ADDR_LIST=...` when running.

### docker/podman arguments

`--stop-timeout 600` is essential to allow the
ETL process sufficient time to copy from the short term (STS)
RAM disk without data loss.

`--shm-size 128m` is setting the size of the STS RAM disk,
which must be sufficient to hold ~2 hours of data.
See the `Storage` report available through the AA web UI.

`--net host` is a suggested starting point as it requires no additional network configuration.
`--net bridge` is another option which provides more isolation while also passing UDP broadcast traffic,
but requires additional network configuration.
