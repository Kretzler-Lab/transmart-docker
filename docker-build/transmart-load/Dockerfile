FROM ubuntu:18.04
MAINTAINER Peter Rice <peter.rice@i2b2transmart.org>

RUN apt-get update && \
     DEBIAN_FRONTEND="noninteractive" TZ="America/New_York" apt-get install -y --no-install-recommends curl unzip make ca-certificates postgresql-client openjdk-8-jdk \
    	    php7.2-cli php7.2-json xz-utils zip perl iproute2 iptables net-tools telnet && \
    useradd --user-group --no-log-init --create-home --home-dir /home/tmload --shell /bin/bash --password tmpassword tmload

WORKDIR /home/tmload

ENV TABLESPACES=dummy \
    PATH=/home/tmload/transmart-data/env:$PATH \
    KETTLE_JOBS_PSQL=/home/tmload/transmart-data/env/transmart-etl/Kettle/postgres/Kettle-ETL/ \
    R_JOBS_PSQL=/home/tmload/transmart-data/env/transmart-etl/Kettle/postgres/R/ \
    KITCHEN=/home/tmload/transmart-data/env/data-integration/kitchen.sh \
    PGHOST=tmdb \
    PGPORT=5432 \
    PGDATABASE=transmart \
    PGUSER=transmartadmin \
    PGPASSWORD=transmart \
    PGSQL_BIN=/usr/bin

WORKDIR /home/tmload

USER tmload

ADD kettle.properties /home/tmload/.kettle/kettle.properties

RUN curl --location --silent --show-error --insecure http://library.transmartfoundation.org/beta/beta19_1_0_artifacts/transmart-data-release-19.1.zip --output transmart-data.zip && \
    unzip -q transmart-data.zip && \
    mv transmart-data-release-19.1 transmart-data && \
    rm transmart-data.zip && \
    mv transmart-data/env /home/tmload/env && \
    mv transmart-data/samples /home/tmload/samples && \
    mv transmart-data/lib /home/tmload/lib && \
    mv transmart-data/Makefile /home/tmload/Makefile && \
    mv transmart-data/makefile.inc /home/tmload/makefile.inc && \
    rm -rf transmart-data/* && \
    rm transmart-data/.gitignore transmart-data/.travis.yml && \
    mv /home/tmload/env transmart-data/ && \
    mv /home/tmload/samples transmart-data/ && \
    mv /home/tmload/lib transmart-data/ && \
    mv /home/tmload/Makefile transmart-data/ && \
    mv /home/tmload/makefile.inc transmart-data/

# install groovy - replace with transmart-data download
# install Pentaho Data Integration (Kettle)

WORKDIR /home/tmload/transmart-data

RUN make -C env groovy data-integration && \
    make -C samples/postgres jdbcdriver && \
    cd env && \
    curl --location --silent --show-error http://library.transmartfoundation.org/beta/beta19_1_0_artifacts/transmart-etl-release-19.1.zip --output transmart-etl.zip && \
    unzip -q transmart-etl.zip && \
    mv transmart-etl-release-19.1 transmart-etl && \
    rm transmart-etl.zip

RUN make update_datasets

CMD ["echo","Use the make commands provided by samples/postgres to load data. E.g. run\ndocker-compose run --rm tmload make -C samples/postgres load_clinical_ElevadaGSE14468\nFor more information go to https://wiki.transmartfoundation.org/display/transmartwiki/Curated+Data."]
