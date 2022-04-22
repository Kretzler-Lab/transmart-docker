FROM tomcat:8.0-jre8
MAINTAINER Peter Rice <peter.rice@i2b2transmart.org>

ENV RUN_USER            tomcat
ENV RUN_GROUP           tomcat

ENV USER_ID 1000
ENV GROUP_ID 1000

# Add a tomcat user
RUN apt-get update && \
    apt-get install -y gosu && \
    curl --location --silent --show-error --insecure http://sativa.home/beta/release19_1_0_artifacts/transmartApp-release-19.1.war --output /usr/local/tomcat/webapps/transmart.war && \
    curl --location --silent --show-error --insecure http://sativa.home/beta/release19_1_0_artifacts/gwava-release-19.1.war --output /usr/local/tomcat/webapps/gwava.war && \
    curl --location --silent --show-error --insecure http://sativa.home/beta/release19_1_0_artifacts/transmart-manual-release-19.1.zip --output /usr/local/tomcat/webapps/transmart-manual.zip && \
    cd /usr/local/tomcat/webapps/ && \
    unzip -q transmart-manual.zip && \
    mv transmart-manual-release-19.1 transmart-manual && \
    rm transmart-manual.zip && \
    groupadd -r ${RUN_GROUP} && \
    useradd -g ${RUN_GROUP} -d ${CATALINA_HOME} -s /bin/bash ${RUN_USER} && \
    chown -R ${RUN_USER}:${RUN_GROUP} ${CATALINA_HOME}

COPY docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 8080

# Use 'run' to keep tomcat running and docker alive

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["catalina.sh", "run"]
