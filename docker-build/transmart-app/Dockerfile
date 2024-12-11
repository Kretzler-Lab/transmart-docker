FROM tomcat:8.5-jre8
MAINTAINER Peter Rice <peter.rice@i2b2transmart.org>

ENV DOCKER_TOMCAT_USER_ID 1000
ENV DOCKER_TOMCAT_GROUP_ID 1000

ENV DOCKER_DB_HOST	tmdb
ENV DOCKER_DB_PORT	5432
ENV DOCKER_DB_DATABASE	transmart
ENV DOCKER_DB_USER	biomart_user
ENV DOCKER_DB_PASSWORD	biomart_user

# Add a tomcat user
RUN apt-get update && \
    apt-get install -y gosu && \
#    curl --location --silent --show-error --insecure http://library.transmartfoundation.org/beta/beta19_1_0_artifacts/gwava-release-19.1.war --output /usr/local/tomcat/webapps/gwava.war && \
#    curl --location --silent --show-error --insecure http://library.transmartfoundation.org/beta/beta19_1_0_artifacts/transmart-manual-release-19.1.zip --output /usr/local/tomcat/webapps/transmart-manual.zip && \
    #cd /usr/local/tomcat/webapps/ && \
    #unzip -q transmart-manual.zip && \
    #mv transmart-manual-release-19.1 transmart-manual && \
    #rm transmart-manual.zip && \
    mkdir -p /usr/local/tomcat/.grails/transmartConfig

COPY transmart.war /usr/local/tomcat/webapps/transmart.war
COPY docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 8080

# Use 'run' to keep tomcat running and docker alive

ENTRYPOINT ["/docker-entrypoint.sh"]
