#!/bin/sh
set -e

# I execute each time the run container starts

die() {
    echo "$1" >&2
    exit 1
}

[ -d /persist ] || die "Missing /persist eg. podman w/ '-v /var/lib/appl:/persist'"

# service account
[ "${ARCHAPPL_UID}" ] || ARCHAPPL_UID=500
[ "${ARCHAPPL_GID}" ] || ARCHAPPL_GID=500
groupadd --system -g $ARCHAPPL_GID appl
useradd --system -u $ARCHAPPL_UID -g appl appl

# copy in default content

[ -e /persist/README ] || install -m444 /usr/share/appl/README.persist /persist/README

[ -d /persist/conf ] || install -m644 -Dt /persist/conf/ /usr/share/appl/conf/*
[ -d /persist/ui ] || install -m644 -Dt /persist/ui/ /usr/share/appl/ui/*

if [ ! -d /persist/db ]
then
    install -m755 -oappl -gappl -d /persist/db/
fi

if ! [ -d /persist/logs ]
then
    for app in mgmt engine etl retrieval
    do
        install -d -m755 -oappl -gappl /persist/logs/$app
        install -d -m755 -oappl -gappl /persist/logs/$app/Catalina
    done
fi

if ! [ -d /persist/sts ]
then
    echo "Using STS container /dev/shm.  cf. --shm-size=64m"
    ln -s /dev/shm /persist/sts
fi

for dd in mts lts
do
    install -d -oappl -gappl -m775 /persist/$dd/ArchiverStore
done

# apply html template changes

if [ -r /persist/ui/template_changes.html ]
then
    java -cp /var/lib/appl/mgmt/webapps/mgmt/WEB-INF/classes \
     org.epics.archiverappliance.mgmt.bpl.SyncStaticContentHeadersFooters \
     /persist/ui/template_changes.html \
     /var/lib/appl/mgmt/webapps/mgmt/ui
fi

if [ -d /persist/ui/img ]
then
    install -m444 -t /var/lib/appl/mgmt/webapps/mgmt/ui/comm/img/ /persist/ui/img/*
fi

# fixup permissions where daemons need to write

# places where the daemon may write

# in the otherwise R/O image
# and in persistant directory.  (Help out user by fixing every time.)
chown -R appl /var/lib/appl/*/temp /var/lib/appl/*/work /persist/db /persist/logs
chmod -R u+w /var/lib/appl/*/temp /var/lib/appl/*/work /persist/db /persist/logs

# not fixing mts/lts as a recursive permissions change may take
# a very long time (eg. large/slow NFS).  Or previous years
# LTS may legitimately be marked R/O
