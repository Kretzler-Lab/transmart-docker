FROM ubuntu:18.04
MAINTAINER Peter Rice <peter.rice@i2b2transmart.org>

ENV LANG en_US.utf8

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl unzip make ca-certificates gnupg apt-utils php7.2-cli php7.2-json sudo  openjdk-8-jdk openjdk-8-jre locales && \
    curl --location --silent --show-error --insecure http://sativa.home/beta/release19_1_0_artifacts/transmart-data-release-19.1.zip --output transmart-data.zip && \
    unzip -q transmart-data.zip && \
    mv transmart-data-release-19.1 transmart-data && \
    rm transmart-data.zip && \
    rm -rf /var/lib/apt/lists/* && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    curl --location --silent --show-error --insecure https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt -y update && \
    DEBIAN_FRONTEND="noninteractive" TZ="America/New_York" apt-get install -y --no-install-recommends postgresql-14 postgresql-client-14 postgresql-contrib-14

#RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Consider dockette:postgres up to 14

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``14``.

# Update repositories and install PostgreSQL 14
# Postgres loads tzdata which needs two variables to load without prompting
# Note: The official Debian and Ubuntu images automatically ``apt-get clean``
# after each ``apt-get``

# Run the rest of the commands as the ``postgres`` user created by the ``postgresql-14`` package when it was ``apt-get installed``

USER postgres

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
# And add ``listen_addresses`` to ``/etc/postgresql/14/main/postgresql.conf``
# Create a PostgreSQL role named ``transmartadmin`` with ``transmart`` as the password

RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/14/main/pg_hba.conf && \
    echo "listen_addresses='*'" >> /etc/postgresql/14/main/postgresql.conf && \
    /etc/init.d/postgresql start && \
    psql --command "CREATE USER transmartadmin WITH SUPERUSER PASSWORD 'transmart';" && \
    /etc/init.d/postgresql stop

#### Load transmart db

USER root

RUN cd transmart-data && make -C env /var/lib/postgresql/tablespaces ../vars groovy && \
    . ./vars && \
    /etc/init.d/postgresql start && \
    make postgres && \
    /etc/init.d/postgresql stop && \
    rm -fR transmart-data && \
    apt-get purge -y --auto-remove curl unzip make php7.2-cli php7.2-json ca-certificates

EXPOSE 5432

# Using defaults calculations from PgTune (https://github.com/le0pard/pgtune)
ADD tunepgsql.sh /usr/bin/tunepgsql.sh

# Add workaround for AUFS issue described at (https://github.com/moby/moby/issues/783#issuecomment-56013588)
RUN chmod +x /usr/bin/tunepgsql.sh && \
    mkdir /etc/ssl/private-copy && \
    mv /etc/ssl/private/* /etc/ssl/private-copy/ && \
    rm -r /etc/ssl/private && \
    mv /etc/ssl/private-copy /etc/ssl/private && \
    chmod -R 0700 /etc/ssl/private && \
    chown -R postgres /etc/ssl/private

USER postgres

ENTRYPOINT ["/usr/lib/postgresql/14/bin/postgres", "-D", "/var/lib/postgresql/14/main", "-c", "config_file=/etc/postgresql/14/main/postgresql.conf"]

