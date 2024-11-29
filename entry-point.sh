#!/bin/sh
set -e -x

ARCHAPPL_MYIDENTITY=${ARCHAPPL_MYIDENTITY:-archappl0}
APP_PORT="${APP_PORT:-17665}"

install -C -m 644 /usr/local/tomcat/README-persist.md /persist/

[ -f /persist/appl.db ] || cp /usr/local/tomcat/empty.db /persist/appl.db

[ -f /persist/policies.py ] || cp /usr/local/tomcat/policies.py /persist/policies.py

[ -f /persist/archappl.properties ] || cp webapps/mgmt/WEB-INF/classes/archappl.properties /persist/archappl.properties

install -d /dev/shm/sts

[ -d /persist/mts ] || install -d /persist/mts

[ -d /persist/lts ] || install -d /persist/lts

[ -f /persist/appliances.xml ] || cat <<EOF > /persist/appliances.xml
<appliances>
    <appliance>
        <identity>${ARCHAPPL_MYIDENTITY}</identity>
        <cluster_inetport>localhost:16001</cluster_inetport>
        <mgmt_url>http://localhost:${APP_PORT}/mgmt/bpl</mgmt_url>
        <engine_url>http://localhost:${APP_PORT}/engine/bpl</engine_url>
        <etl_url>http://localhost:${APP_PORT}/etl/bpl</etl_url>
        <retrieval_url>http://localhost:${APP_PORT}/retrieval/bpl</retrieval_url>
        <data_retrieval_url>http://localhost:${APP_PORT}/retrieval</data_retrieval_url>
    </appliance>
</appliances>
EOF

cat <<EOF > /usr/local/tomcat/conf/context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context>
    <Manager pathname="" />
<Resource name="jdbc/archappl"
        auth="Container"
        type="javax.sql.DataSource"
        driverClassName="org.sqlite.JDBC"
        url="jdbc:sqlite:/persist/appl.db"
        factory="org.apache.tomcat.dbcp.dbcp2.BasicDataSourceFactory"
 />
</Context>
EOF


[ -f "/persist/server.xml" ] || cat <<EOF > /persist/server.xml
<?xml version="1.0" encoding="UTF-8"?>
<Server port="-1">
  <Listener className="org.apache.catalina.startup.VersionLoggerListener" />
  <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />
  <GlobalNamingResources>
    <Resource name="UserDatabase" auth="Container"
              type="org.apache.catalina.UserDatabase"
              description="User database that can be updated and saved"
              factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
              pathname="conf/tomcat-users.xml" />
  </GlobalNamingResources>
  <Service name="Catalina">
    <Connector port="${APP_PORT}" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
    <Engine name="Catalina" defaultHost="localhost">
      <Realm className="org.apache.catalina.realm.LockOutRealm">
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
               resourceName="UserDatabase"/>
      </Realm>
      <Host name="localhost"  appBase="webapps"
            unpackWARs="true" autoDeploy="true">
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log" suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />

      </Host>
    </Engine>
  </Service>
</Server>
EOF

export ARCHAPPL_APPLIANCES=/persist/appliances.xml
export ARCHAPPL_POLICIES=/persist/policies.py
export ARCHAPPL_SHORT_TERM_FOLDER=/dev/shm/sts
export ARCHAPPL_MEDIUM_TERM_FOLDER=/persist/mts
export ARCHAPPL_LONG_TERM_FOLDER=/persist/lts
export ARCHAPPL_PROPERTIES_FILENAME=/persist/archappl.properties
export ARCHAPPL_MYIDENTITY
export CATALINA_OUT=/dev/stdout

CMD="$1"
shift
case "$CMD" in
run) true ;;
init) exit 0 ;;
*) echo "Unknown arg: $1"; exit 1 ;;
esac

exec /usr/local/tomcat/bin/catalina.sh run
