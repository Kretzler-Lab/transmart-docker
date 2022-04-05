FROM ubuntu:18.04
MAINTAINER Peter Rice <peter.rice@i2b2transmart.org>

RUN apt-get update && apt-get install -y --no-install-recommends curl make rsync patch php7.2-cli php7.2-json openjdk-8-jdk openjdk-8-jre unzip && \
    useradd --user-group --no-log-init --create-home --home-dir /home/solruser --shell /bin/bash --password solrpassword solruser

WORKDIR /home/solruser

RUN curl --location --silent --show-error http://sativa.home/beta/release19_1_0_artifacts/transmart-data-release-19.1.zip -o transmart-data.zip && \
    unzip -q transmart-data.zip && \
    mv transmart-data-release-19.1 transmart-data && \
    rm transmart-data.zip

WORKDIR /home/solruser/transmart-data

ENV TABLESPACES=dummy PGHOST=tmdb PGPORT=5432 PGDATABASE=transmart

RUN mv makefile.inc  /home/solruser/makeinc && \
    mv solr /home/solruser/solr && \
    mv lib /home/solruser/solrlib && \
    rm -rf /home/solruser/transmart-data/* && \
    rm -rf .gitignore .travis.yml && \
    mv /home/solruser/makeinc /home/solruser/transmart-data/makefile.inc && \
    mv /home/solruser/solr /home/solruser/transmart-data/ && \
    mv /home/solruser/solrlib /home/solruser/transmart-data/lib && \
    make -C solr solr-4.5.0.tgz && \
    make -C solr solr_home && \
    apt-get purge -y --auto-remove curl rsync patch php7.2-cli php7.2-json && \
    rm -rf /var/lib/apt/lists/* && \
    chown -R solruser:solruser /home/solruser/transmart-data

USER solruser

# Clean up the unwanted transmart-data files
# Save only the solr directory

EXPOSE 8983

WORKDIR /home/solruser/transmart-data/solr

ENTRYPOINT ["java", "-jar", "start.jar"]
