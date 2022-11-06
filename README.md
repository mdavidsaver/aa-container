# Archiver Appliance Demo Container

Scripts to build an OCI container image with a standalone EPICS Archiver Appliance (aka. "AA").

The images produced are intended those new to AA and/or to Linux containers.
Some assumptions specific to small to medium sized installations are made.
(eg. no support for multi-host clusters)

See:

- https://github.com/slacmshankar/epicsarchiverap
- https://slacmshankar.github.io/epicsarchiver_docs/

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
files (`/persist` in the container) will be stored under `/var/lib/appl` on the host filesystem.

See [README-persist.md](README-persist.md) for details.

For simplicity, host networking (`--net host`) is used.
Those familiar with `podman`/`docker` may wish to investigate
alternative like `bridge` which provide more isolation, but
which also require additional site specific configuration.

### Host filesystem layout

Create an empty directory.

```sh
sudo install -d /var/lib/appl
```

### First run

If empty, the `/var/lib/appl` will be populated with defaults
the first time the image runs.

```sh
sudo podman run --rm -ti \
 -v /var/lib/appl:/persist \
 --net host \
 --stop-timeout 600 \
 --shm-size 128m \
 --name appltest \
 epicsarchiverap
```

Wait until the following is seen:

```
[  OK  ] Finished EPICS Archiver Appliance.
```

As a test, in another terminal/shell run:

```sh
curl http://localhost:17665/mgmt/ui/storage.html
```

Now shutdown the `appltest` container.
In another terminal/shell run:

```sh
sudo podman stop appltest
```

`/var/lib/appl` should now be populated with a default configuration.

```
$ ls /var/lib/appl/
conf  db  logs  lts  mts  README  sts  ui
```

### Required configuration

At minimum, `/var/lib/appl/conf/appliance.xml` __must__ be edited
to replace `localhost` with the actual hostname or IP address
through which the AA daemon will be reached.

eg. if the system hostname is correctly configured.

```sh
sudo sed -ie "s|localhost|$(hostname)|" /var/lib/appl/conf/appliance.xml
```

See [README-persist.md](README-persist.md) for details on other files.

### Create/Start regular container

For simplicity, create a persistent container.

```sh
sudo podman create \
 -v /var/lib/appl:/persist \
 --net host \
 --stop-timeout 600 \
 --shm-size 128m \
 --name appl \
 epicsarchiverap
```

Which can be started manually with:

```sh
sudo podman start appl
```

or via systemd.

```sh
sudo podman generate systemd -n -f appl
sudo cp container-appl.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start container-appl.service
sudo systemctl enable container-appl.service
```

### Test

Visit `http://localhost:17665/mgmt/ui/index.html`.

Where `localhost` should be replaced with the hostname
previously placed in `appliance.xml`.

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

Add `JAVA_OPTS=` in `/persist/conf/environ.conf`.

```
JAVA_OPTS=-Djava.awt.headless=true -Xmx128m
```

### EPICS Channel Access Options

See `/persist/conf/environ.conf`.

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
