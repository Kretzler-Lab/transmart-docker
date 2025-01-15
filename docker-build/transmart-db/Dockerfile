FROM ubuntu:22.04
MAINTAINER Zach Wright <zwright@umich.edu>

ENV LANG en_US.utf8

COPY ./transmart-data /transmart-data
COPY miktmc_custom.sql /miktmc_custom.sql

RUN printf '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y --no-install-recommends curl unzip make ca-certificates gnupg apt-utils php7.2-cli php7.2-json sudo  openjdk-8-jdk openjdk-8-jre locales && \
    rm -rf /var/lib/apt/lists/* && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    curl --location --silent --show-error --insecure https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt -y update && \
    apt install -y postgresql-common && \
    yes '' | /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh && \
    DEBIAN_FRONTEND="noninteractive" TZ="America/New_York" apt-get install -y --no-install-recommends iproute2 iptables net-tools postgresql-15 postgresql-client-15 postgresql-contrib-15

USER postgres

RUN echo "host all  all    samenet  md5" >> /etc/postgresql/15/main/pg_hba.conf && \
    echo "# Docker network IP addresses:" >> /etc/postgresql/15/main/pg_hba.conf && \
    echo "#host all  all    172.17.0.0/16 md5" >> /etc/postgresql/15/main/pg_hba.conf && \
    echo "listen_addresses='*'" >> /etc/postgresql/15/main/postgresql.conf

USER postgres

RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER transmartadmin WITH SUPERUSER PASSWORD 'transmart';" && \
    /etc/init.d/postgresql stop

#### Load transmart db

USER root

RUN cd transmart-data && make -C env /var/lib/postgresql/tablespaces ../vars groovy && \
    . ./vars && \
    /etc/init.d/postgresql start && \
    make postgres && \
    cat /miktmc_custom.sql | psql && \
    /etc/init.d/postgresql stop && \
    rm -fR transmart-data && \
    apt-get purge -y --auto-remove curl unzip make php7.2-cli php7.2-json ca-certificates

EXPOSE 5432

USER postgres

ENTRYPOINT ["/usr/lib/postgresql/15/bin/postgres", "-D", "/var/lib/postgresql/15/main", "-c", "config_file=/etc/postgresql/15/main/postgresql.conf"]

