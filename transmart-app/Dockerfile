FROM tomcat:8-jdk8
MAINTAINER Peter Rice <peter.rice@i2b2transmart.org>

RUN curl --location --silent --show-error --insecure http://sativa.home/beta/release19_1_0_artifacts/transmartApp-release-19.1.war --output /usr/local/tomcat/webapps/transmart.war && \
    curl --location --silent --show-error --insecure http://sativa.home/beta/release19_1_0_artifacts/gwava-release-19.1.war --output /usr/local/tomcat/webapps/gwava.war && \
    curl --location --silent --show-error --insecure http://sativa.home/beta/release19_1_0_artifacts/transmart-manual-release-19.1.zip --output /usr/local/tomcat/webapps/transmart-manual.zip && \
    cd /usr/local/tomcat/webapps/ && \
    unzip -q transmart-manual.zip && rm transmart-manual.zip && \
    sed -i 's#securerandom.source=file:/dev/random#securerandom.source=file:/dev/urandom#' /usr/local/openjdk-8/jre/lib/security/java.security

ENV JAVA_HOME=/usr/local/openjdk-8

# change the random number generator to /dev/urandom, since inside a container there is not a lot of
# entropy to feed /dev/random and it will block for a long time when starting the application

# Finally runs tomcat8 pre-defined in tomcat:8-jdk8
