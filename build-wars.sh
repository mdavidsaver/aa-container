#!/bin/sh
set -e -x

cd "$(dirname "$(readlink -f "$0")")"

apt-get update
apt-get -y --no-install-recommends install \
 git ant wget default-jdk-headless tomcat9-user

[ -d epicsarchiverap ] \
|| git clone --recursive https://github.com/slacmshankar/epicsarchiverap.git

ls epicsarchiverap/lib/sqlite-jdbc-*.jar \
|| (cd epicsarchiverap/lib && wget https://github.com/xerial/sqlite-jdbc/releases/download/3.39.2.0/sqlite-jdbc-3.39.2.0.jar)

install -d wars
cd epicsarchiverap

TOMCAT_HOME=/usr/share/tomcat9 \
JAVA_HOME=/usr/lib/jvm/default-java \
ant "-Dwardest=$PWD/../wars"
