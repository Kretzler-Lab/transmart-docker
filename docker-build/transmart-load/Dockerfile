FROM ubuntu:18.04
MAINTAINER MiKTMC Developers <miktmc-devs@umich.edu>

RUN apt-get update && \
     DEBIAN_FRONTEND="noninteractive" TZ="America/New_York" apt-get install -y --no-install-recommends curl unzip make ca-certificates postgresql-client openjdk-8-jdk \
    	    php7.2-cli php7.2-json xz-utils zip perl iproute2 iptables net-tools telnet vim sudo && \
    useradd --user-group --no-log-init --create-home --home-dir /home/tmload --shell /bin/bash --password $(perl -e 'print crypt($ARGV[0], "password")' 'tmpassword') tmload && \
    adduser tmload sudo

WORKDIR /home/tmload

ENV TABLESPACES=dummy \
    PATH=/home/tmload/transmart-data:$PATH \
    KETTLE_JOBS_PSQL=/home/tmload/transmart-etl/Kettle/postgres/Kettle-ETL/ \
    R_JOBS_PSQL=/home/tmload/transmart-etl/Kettle/postgres/R/ \
    KITCHEN=/home/tmload/data-integration/kitchen.sh \
    PGHOST=tmdb \
    PGPORT=5432 \
    PGDATABASE=transmart \
    PGUSER=transmartadmin \
    PGPASSWORD=transmart \
    PGSQL_BIN=/usr/bin

WORKDIR /home/tmload

USER tmload

ADD transmart-data.zip transmart-data.zip

RUN unzip -q transmart-data.zip && \
    rm transmart-data.zip

ADD kettle.properties /home/tmload/transmart-data/samples/postgres/kettle-home/.kettle/kettle.properties

ADD vars transmart-data/vars
ADD transmart-etl.zip transmart-etl.zip
ADD data-integration.zip data-integration.zip
RUN unzip -q data-integration.zip && \
    rm data-integration.zip 

RUN unzip -q transmart-etl.zip && \
    mv tranSMART-ETL transmart-etl && \
    rm transmart-etl.zip

CMD ["echo","Use the make commands provided by samples/postgres to load data. E.g. run\ndocker-compose run --rm tmload make -C samples/postgres load_clinical_ElevadaGSE14468\nFor more information go to https://wiki.transmartfoundation.org/display/transmartwiki/Curated+Data."]
