#!/bin/sh
set -e -x

# I execute to populate the run container

cd "$(dirname "$(readlink -f "$0")")"
[ -r wait-ready.sh ] || exit 1
[ -r /wars/mgmt.war ] || exit 1

# packaged deps.
apt-get update
apt-get -y --no-install-recommends install \
 sqlite3 unzip rsync rdfind wget systemd-sysv default-jre-headless tomcat9-user

install -d /usr/share/appl/db

rsync -av \
 wait-ready.sh first-time.sh README-persist.md \
 conf ui \
 /usr/share/appl/

rsync -av system/ /etc/systemd/system/

unzip -j /wars/mgmt.war \
 WEB-INF/classes/policies.py \
 WEB-INF/classes/archappl.properties \
 -d /usr/share/appl/conf/

# journald log to console for capture by host logger
echo "ForwardToConsole=yes" >> /etc/systemd/journald.conf

# avoid annoying non-functional prompt
systemctl disable console-getty.service
systemctl mask console-getty.service

# prepare daemon instance configs

install -d /var/lib/appl

tomcat9-instance-create -p 17665 -c 16665 -w SHUTDOWNMGMT /var/lib/appl/mgmt
tomcat9-instance-create -p 17666 -c 16666 -w SHUTDOWNENG  /var/lib/appl/engine
tomcat9-instance-create -p 17667 -c 16667 -w SHUTDOWNETL  /var/lib/appl/etl
tomcat9-instance-create -p 17668 -c 16668 -w SHUTDOWNRET  /var/lib/appl/retrieval

for app in mgmt engine etl retrieval
do
    install -d /var/lib/appl/$app/webapps/$app
    install -d /var/lib/appl/$app/lib

    # unpack .war so that we can make webapps/ read-only
    (cd /var/lib/appl/$app/webapps/$app && unzip /wars/$app.war)

    # link to global config files
    ln -fs /persist/conf/context.xml /var/lib/appl/$app/conf/
    ln -s /persist/conf/log4j.properties /var/lib/appl/$app/lib/

    # persist logs
    rmdir /var/lib/appl/$app/logs
    ln -s /persist/logs/$app /var/lib/appl/$app/logs
    ln -s /persist/logs/$app/Catalina /var/lib/appl/$app/conf/Catalina
done

# almost all of the files contained in the four .war archives are identical.
# Replace duplicates with hard links to reduce image size
rdfind -makehardlinks true /var/lib/appl/*

# actually hook into startup
systemctl enable archappl.service


# minimize space
apt-get -y remove --purge sqlite3 rsync unzip rdfind
apt-get clean
rm -rf /var/cache/* /var/lib/apt/lists/* /tmp/*
