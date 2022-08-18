#!/bin/sh
set -e

echo "Waiting for Archiver to become ready"

# loop forever.  cf. TimeoutStartSec= in archappl.service
while ! wget -qO /dev/null http://localhost:17665/mgmt/ui/index.html
do
    echo "... waiting"
    sleep 5
done

echo "Archiver Ready"
