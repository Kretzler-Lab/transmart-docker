FROM ubuntu:18.04
MAINTAINER Peter Rice <peter.rice@i2b2transmart.org>

RUN apt-get update && apt-get install -y --no-install-recommends curl unzip make ca-certificates postgresql-client openjdk-8-jdk php7.2-cli php7.2-json xz-utils zip && \
    useradd --user-group --no-log-init --create-home --home-dir /home/tmload --shell /bin/bash --password tmpassword tmload

WORKDIR /home/tmload

RUN curl --location --silent --show-error --insecure http://sativa.home/beta/release19_1_0_artifacts/transmart-data-release-19.1.zip --output transmart-data.zip && \
    unzip -q transmart-data.zip && \
    mv transmart-data-release-19.1 transmart-data && \
    rm transmart-data.zip

ADD kettle.properties /home/tmload/.kettle/kettle.properties

ENV TABLESPACES=dummy \
    PATH=/home/tmload/transmart-data/env:$PATH \
    KETTLE_JOBS_PSQL=/home/tmload/transmart-data/env/transmart-etl/Kettle/postgres/Kettle-ETL/ \
    KITCHEN=/home/tmload/transmart-data/env/data-integration/kitchen.sh \
    PGHOST=tmdb \
    PGPORT=5432 \
    PGDATABASE=transmart \
    PGUSER=transmartadmin \
    PGPASSWORD=transmart \
    PGSQL_BIN=/usr/bin

WORKDIR /home/tmload/transmart-data

# install groovy - replace with transmart-data download
# install Pentaho Data Integration (Kettle)

RUN make -C env groovy data-integration && \
    make update_datasets && \
    mv env /home/tmload/env && \
    mv samples /home/tmload/samples && \
    rm -rf /home/tmload/transmart-data/* && \
    rm -rf .gitignore .travis.yml && \
    mv /home/tmload/env /home/tmload/transmart-data/ && \
    mv /home/tmload/samples /home/tmload/transmart-data/ && \
    cd env && curl --location --silent --show-error http://sativa.home/beta/release19_1_0_artifacts/transmart-etl-release-19.1.zip --output transmart-etl.zip && \
    unzip transmart-etl.zip && \
    rm transmart-etl.zip && \
    chown -R tmload:tmload /home/tmload/transmart-data

USER tmload

CMD ["echo","Use the make commands provided by samples/postgres to load data. E.g. run\ndocker-compose run --rm tmload make -C samples/postgres load_clinical_ElevadaGSE14468\nFor more information go to https://wiki.transmartfoundation.org/display/transmartwiki/Curated+Data."]
