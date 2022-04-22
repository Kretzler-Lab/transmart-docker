#!/bin/bash
set -e

USER_ID=${TOMCAT_USER_ID:-1000}
GROUP_ID=${TOMCAT_GROUP_ID:-1000}

echo "docker-entrypoint.sh"
pwd
ls -al /usr/local/tomcat

###
# Tomcat user
###
#groupadd -r tomcat -g ${GROUP_ID}
#useradd --shell /bin/bash -u ${USER_ID} -g tomcat --home-dir ${CATALINA_HOME} \
#        --comment "Tomcat user" tomcat

###
# Change CATALINA_HOME ownership to tomcat user and tomcat group
# Restrict permissions on conf
###

#chown -R tomcat:tomcat ${CATALINA_HOME} && chmod 400 ${CATALINA_HOME}/conf/*
sync
exec gosu tomcat "$@"

exec "$@"
