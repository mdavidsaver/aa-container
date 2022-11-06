# Persistant Configuration and Data

If not present, the contents of the /persist
directory will be created with defaults.

- conf/appliances.xml

The default contains "localhost" which should
be replaced with the externally visible host name or IP address.

- conf/environ.conf

A systemd EnvironmentFile used to set additional
environment variables to the AA processes.
eg. EPICS_CA_* settings.

- conf/log4j.properties

Daemon logging settings.

- conf/context.xml

Contains config database settings.

- conf/policies.py

Logging policies hook script.

- logs/*

Log files for the four AA daemon processes.

Must be writable by the daemon user

- db/

Configuration database.

Must be writable by the daemon user

- sts/

Short term storage.

By default, a symlink to /dev/shm **in the container**.

It is highly recommended that STS be a RAM disk or
similarly low latency storage.

Must be writable by the daemon user

- mts/
- lts/

Long and Medium term storage.

Must be writable by the daemon user
