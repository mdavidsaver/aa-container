# Persistant Configuration and Data

If not present, the contents of the /persist
directory will be created with defaults.

Must be writable by the daemon user

- appliances.xml

Created with `localhost`.
Most user will edit to replace with actual effective hostname.

- policies.py

Logging policies hook script.

- archappl.properties

Archiver specific configuration.

- appl.db

Configuration database.

- mts/
- lts/

Long and Medium term storage.

Must be writable by the daemon user

- README-persist.md

This file.  Will be overwritten with original if modified.
