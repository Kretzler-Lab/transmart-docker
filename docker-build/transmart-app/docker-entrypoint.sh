#!/bin/bash
set -e

USER_ID=${TOMCAT_USER_ID:-1000}
GROUP_ID=${TOMCAT_GROUP_ID:-1000}

echo "docker-entrypoint.sh"
pwd
printenv

###
# Tomcat user defined here so caller can set UID and GID to match a local non-privileged user
###
groupadd --system tomcat -g ${GROUP_ID} || echo "Group tomcat already exists."
useradd --shell /bin/bash --uid ${USER_ID} --gid tomcat --home-dir ${CATALINA_HOME} \
        --comment "Tomcat user" tomcat  || echo "User tomcat already exists."

###
# Change CATALINA_HOME ownership to tomcat user and tomcat group
# Restrict permissions on conf
# Change here to match user-controlled UID and GID
###

chown -R tomcat:tomcat ${CATALINA_HOME} && chmod 400 ${CATALINA_HOME}/conf/*

echo "ls -alR /usr/local/tomcat"
echo "-------------------------"
ls -alR /usr/local/tomcat

echo "ls -al /usr/local/tomcat/.grails"
echo "--------------------------------"
ls -al /usr/local/tomcat/.grails

echo "dosu tomcat ls -alR ~tomcat/.grails/transmartConfig"
echo "---------------------------------------------"
gosu tomcat ls -alR ~tomcat/.grails/transmartConfig

echo "cat DataSource.groovy"
echo "---------------------"
cat /usr/local/tomcat/.grails/transmartConfig/DataSource.groovy

echo "cat /etc/hosts"
cat /etc/hosts

echo "=== done ==="


sync
exec gosu tomcat catalina.sh run
