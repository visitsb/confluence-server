# Dockerfile adapted from original confluence-server. Most of the portions are
# kept as-is, with some reorganization done to reduce number of instructions
# https://bitbucket.org/atlassian-docker/docker-atlassian-confluence-server/src
FROM adoptopenjdk:8-hotspot
MAINTAINER Shanti Naik <visitsb@gmail.com>

ENV RUN_USER daemon
ENV RUN_GROUP daemon

# https://confluence.atlassian.com/doc/confluence-home-and-other-important-directories-590259707.html
ENV CONFLUENCE_HOME /var/atlassian/application-data/confluence
ENV CONFLUENCE_INSTALL_DIR /opt/atlassian/confluence

VOLUME ["${CONFLUENCE_HOME}"]
WORKDIR $CONFLUENCE_HOME

ARG TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/local/bin/tini

COPY entrypoint.sh /usr/local/bin/

# Using MySQL JDBC drivers
ARG MYSQL_CONNECTOR_VERSION=5.1.49
ADD https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz .

# My purchased license expired 22 Apr 2016, below is the version upto which I can go latest
# https://confluence.atlassian.com/doc/confluence-5-9-9-release-notes-824149480.html
# 5.9.9  - 21 April 2016 (*)
# 5.9.10 - 05 May 2016   (x)
ARG CONFLUENCE_VERSION=5.9.9
ADD https://product-downloads.atlassian.com/software/confluence/downloads/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz .

RUN /usr/bin/apt-get update \
 && /usr/bin/apt-get install -y --no-install-recommends fontconfig \
 && /usr/bin/apt-get clean autoclean && /usr/bin/apt-get autoremove -y && /bin/rm -rf /var/lib/apt/lists/* \
 && /bin/chmod +x /usr/local/bin/tini /usr/local/bin/entrypoint.sh \
 && /bin/mkdir -p ${CONFLUENCE_INSTALL_DIR} \
 && /bin/tar -xzvf ./atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz --strip-components=1 -C "${CONFLUENCE_INSTALL_DIR}" \
 && /bin/chown -R ${RUN_USER}:${RUN_GROUP} ${CONFLUENCE_INSTALL_DIR}/ \
 && /bin/tar -xzvf ./mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz \
 && /bin/mv ./mysql-connector-java-${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar ${CONFLUENCE_INSTALL_DIR}/confluence/WEB-INF/lib \
 && /bin/rm -f ./atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz \
 && /bin/rm -f ./mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz \
 && /bin/rm -rf ./mysql-connector-java-${MYSQL_CONNECTOR_VERSION} \
 && /bin/sed -i -e 's/-Xms\([0-9]\+[kmg]\) -Xmx\([0-9]\+[kmg]\)/-Xms\${JVM_MINIMUM_MEMORY:=\1} -Xmx\${JVM_MAXIMUM_MEMORY:=\2} \${JVM_SUPPORT_RECOMMENDED_ARGS} -Dconfluence.home=\${CONFLUENCE_HOME}/g' ${CONFLUENCE_INSTALL_DIR}/bin/setenv.sh \
 && /bin/sed -i -e 's/port="8090"/port="8090" secure="${catalinaConnectorSecure}" scheme="${catalinaConnectorScheme}" proxyName="${catalinaConnectorProxyName}" proxyPort="${catalinaConnectorProxyPort}"/' ${CONFLUENCE_INSTALL_DIR}/conf/server.xml \
 && /bin/sed -i -e 's/Context path=""/Context path="${catalinaContextPath}"/' ${CONFLUENCE_INSTALL_DIR}/conf/server.xml

# Expose HTTP and Synchrony ports
EXPOSE 8090
EXPOSE 8091

CMD ["entrypoint.sh", "-fg"]
ENTRYPOINT ["tini", "--"]
