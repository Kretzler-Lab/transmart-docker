FROM ubuntu:20.04
LABEL maintainer="MiKTMC Developers <miktmc-devs@umich.edu>"

RUN apt-get update && \
     DEBIAN_FRONTEND="noninteractive" TZ="America/New_York" apt-get install -y --no-install-recommends curl git unzip make ca-certificates postgresql-client openjdk-8-jdk \
    	    php7.4-cli php7.4-json xz-utils zip perl iproute2 iptables dos2unix net-tools telnet vim sudo && \
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

USER tmload

RUN git init transmart && \
    cd transmart && \
    git remote add origin https://github.com/Kretzler-Lab/transmart.git && \
    git sparse-checkout init --cone && \
    git sparse-checkout set transmart-data transmart-etl && \
    git pull --depth=1 origin develop && \
    cd .. && \
    ln -s transmart/transmart-data transmart-data && \
    ln -s transmart/transmart-etl transmart-etl

RUN curl -O https://miktmc-artifact-repository-public.s3.us-east-2.amazonaws.com/data-integration.zip
RUN unzip -q data-integration.zip && rm data-integration.zip
ADD load_clinical.sh load_clinical.sh
ADD load_expression.sh load_expression.sh
ADD set_db_host.sh set_db_host.sh
ADD kettle.properties /home/tmload/transmart-data/samples/postgres/kettle-home/.kettle/kettle.properties

ADD vars transmart-data/vars

CMD ["echo","Use the make commands provided by samples/postgres to load data. E.g. run\ndocker-compose run --rm tmload make -C samples/postgres load_clinical_ElevadaGSE14468\nFor more information go to https://wiki.transmartfoundation.org/display/transmartwiki/Curated+Data."]
