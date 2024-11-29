FROM docker.io/library/gradle:8-jdk17-jammy AS wars

RUN apt-get update \
 && apt-get -y install wget git sqlite3 rdfind python-is-python3 python3-venv python3-pip \
 && rm -rf /var/lib/apt/lists /var/cache/apt

RUN wget -nv https://github.com/xerial/sqlite-jdbc/releases/download/3.47.1.0/sqlite-jdbc-3.47.1.0.jar

RUN git clone --depth 1 --branch 2.0.5 https://github.com/archiver-appliance/epicsarchiverap

# generateReleaseNotes incompatible with shallow clone
RUN cd epicsarchiverap \
 && gradle assemble -x generateReleaseNotes \
 && rm build/libs/epicsarchiverap-*.war \
 && ls -h build/libs/*.war build/distributions/archappl_v*.tar.gz

# unpack and de-duplicate 4x .war files
RUN for name in mgmt engine etl retrieval ; do \
      install -d /usr/local/tomcat/webapps/$name \
      && ( cd /usr/local/tomcat/webapps/$name && unzip /home/gradle/epicsarchiverap/build/libs/$name.war ) \
      && cp /home/gradle/sqlite-jdbc-*.jar /usr/local/tomcat/webapps/$name/WEB-INF/lib/ \
      || exit 1 ; \
    done \
    && rdfind -makehardlinks true /usr/local/tomcat/webapps/* \
    && sqlite3 -init epicsarchiverap/src/main/org/epics/archiverappliance/config/persistence/archappl_sqlite.sql empty.db

FROM docker.io/library/tomcat:9-jdk17
LABEL org.opencontainers.image.authors="mdavidsaver@gmail.com" \
      org.opencontainers.image.source="https://github.com/mdavidsaver/aa-container"

COPY --from=wars \
 /usr/local/tomcat/webapps \
 /usr/local/tomcat/webapps/

COPY --from=wars \
 /home/gradle/empty.db \
 /home/gradle/epicsarchiverap/docker/archappl/conf/policies.py \
 /usr/local/tomcat/

COPY README-persist.md ./entry-point.sh /usr/local/tomcat/

COPY ROOT /usr/local/tomcat/webapps/ROOT

COPY template_changes.html /usr/local/tomcat/webapps/mgmt/

COPY ui /usr/local/tomcat/webapps/mgmt/ui/

RUN install -d /persist \
 && chmod a+x /usr/local/tomcat/entry-point.sh \
 && ln -fs /persist/server.xml /usr/local/tomcat/conf/server.xml \
 && ln -fs /persist/context.xml /usr/local/tomcat/conf/context.xml \
 && java -cp /usr/local/tomcat/webapps/mgmt/WEB-INF/classes \
    org.epics.archiverappliance.mgmt.bpl.SyncStaticContentHeadersFooters \
    /usr/local/tomcat/webapps/mgmt/template_changes.html \
    /usr/local/tomcat/webapps/mgmt/ui

USER 1000:1000

ENTRYPOINT ["/usr/local/tomcat/entry-point.sh"]
