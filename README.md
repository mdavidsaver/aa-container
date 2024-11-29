# Archiver Appliance Demo Container

Source for an OCI container image with a standalone EPICS Archiver Appliance (aka. "AA").

The images produced are intended for those who are new to AA and/or to Linux containers.
Some assumptions specific to small to medium sized installations are made.

See:

- https://github.com/archiver-appliance/epicsarchiverap
- https://epicsarchiver.readthedocs.io/en/latest/index.html

## Important Caveats

- Intended for small to medium sized installations.
  - No support for clusters.
  - Configuration stored in a single SQLite database file instead of mysql/mariadb engine.
    - SQLite file __must__ not be on network storage!  (data on NFS is normal)
- `/persist/conf/appliance.xml` __must__ be manually edited!

## Current Status

Pre-built images are not currently published.

See [container.yml](.github/workflows/container.yml).

## Getting Started

An unprivileged container environment is expected.

The following assumes a "simple" layout, where all AA related
files are stored under `/persist` in the container.

Host networking (`--net host`) is used.
Those familiar with `podman`/`docker` may wish to investigate
alternative like `bridge` which provide more isolation, but
which also require additional site specific configuration
beyond the scope of this example.

### Host dependencies

Install `podman`.  eg.

```sh
sudo apt-get install git podman
```

or

```sh
sudo dnf install git podman
```

### Build image

```sh
git clone https://github.com/mdavidsaver/aa-container
cd aa-container
podman build -t epicsarchiverap .
```

On success, the `epicsarchiverap:latest` tag will appear in: `podman image list`.

### Host filesystem

Create an empty directory writable by UID 1000 within the container.

This directory may be created anywhere on the host filesystem,
and with any name, but must always appear as `/persist` within
the container.
(eg. [`--volume "$PWD"/persist:/persist`](https://docs.podman.io/en/stable/markdown/podman-build.1.html#volume-v-host-dir-container-dir-options))

```sh
podman unshare install -d -o 1000 -g 1000 persist
```

### First run

Prepare a host directory to mount as `/persist` within the container.

```sh
podman unshare install -d -o 1000 -g 1000 persist
```

Note: For later cleanup, this directory can be removed with `podman unshare rm -rf persist`.

May run first with `init` to populate `/persist` with default configuration
and then exit.

```sh
podman run --rm \
 -v "$PWD"/persist:/persist \
 --net host \
 --env APP_PORT=17665 \
 --env ARCHAPPL_MYIDENTITY=archappl0 \
 epicsarchiverap init
```

Note: `--env APP_PORT=17665` or `--env ARCHAPPL_MYIDENTITY=archappl0` are defaults,
and may be omitted.

## Running

```sh
podman run --rm \
 --name archappl \
 -v "$PWD"/persist:/persist \
 --stop-timeout=600 \
 --net host \
 epicsarchiverap run
```

This will run until interrupted with `SIGINT` or `SIGTERM`,
or alternatively by running: `podman stop --name archappl -t 600`.

### Test

Visit `http://localhost:17665/mgmt/ui/index.html`.

Where `localhost` should be substituted with the hostname.

## Customization

Most static configuration is through the directory bound as [`/persist`](README-persist.md).

### Separate data storage

eg. To place the Long Term Storage (LTS) data in a different location
add the following to all `podman run` and `podman create` after
the bind for `/persist`.

```
-v /example/lts_data:/persist/lts
```

### JVM Options

Add `-e CATALINA_OPTS=...` when running.

```
CATALINA_OPTS=-Djava.awt.headless=true -Xmx128m
```

### EPICS Channel Access Options

Add eg. `-e EPICS_CA_ADDR_LIST=...` when running `podman`.

### docker/podman arguments

`--stop-timeout 600` is essential to allow the
ETL process sufficient time to copy from the short term (STS)
RAM disk without data loss.

`--shm-size 128m` sets the size of the STS RAM disk,
which must be sufficient to hold ~2 hours of data.
See the `Storage` report available through the AA web UI.

`--net host` is a suggested starting point as it requires no additional network configuration.
`--net bridge` is another option which provides more isolation while also passing UDP broadcast traffic,
but requires additional network configuration.

### systemd configuration

An example configuration of a `systemd` user unit
([`system/archappl.service`](system/archappl.service))
is provided.

```sh
podman unshare install -d -o 1000 -g 1000 ~/archappl-data
systemctl --user edit --full --force archappl.service
# paste in contents of system/archappl.service
systemctl --user start archappl.service
# test... then enable automatic start on boot
systemctl --user enable archappl.service
```

Notes:

- User account be configured with subuid/subgid.
  eg. `useradd --system` must also pass `--add-subids-for-system`.
- User account must "linger" to start automatically.
  eg. `sudo loginctl enable-linger $USER`.

### HTML Template

[`template_changes.html`](template_changes.html) will be applied,
and the contents of `ui/` copied into the container.
