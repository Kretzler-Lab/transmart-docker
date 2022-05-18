FROM ubuntu:18.04
MAINTAINER Peter Rice <peter.rice@i2b2transmart.org>

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl unzip make ca-certificates openjdk-8-jdk openjdk-8-jre && \
    useradd --user-group --no-log-init --create-home --home-dir /home/ruser --shell /bin/bash --password rpassword ruser && \
    DEBIAN_FRONTEND="noninteractive" TZ="America/New_York" apt-get install -y libcairo-dev gfortran g++ \
        libreadline-dev libxt-dev libpango1.0-dev libprotoc-dev \
    	texlive-fonts-recommended tex-gyre texlive-latex-extra liblz4-tool pv \
    	libbz2-dev liblzma-dev libcurl4-openssl-dev libjpeg-dev libxml2-dev libssl-dev libpcre2-dev

USER ruser

WORKDIR /home/ruser

RUN curl --location --silent --show-error http://library.transmartfoundation.org/beta/beta19_1_0_artifacts/transmart-data-release-19.1.zip -o transmart-data.zip && \
    unzip -q transmart-data.zip && \
    mv transmart-data-release-19.1 transmart-data && \
    rm transmart-data.zip && \
    mv transmart-data/R /home/ruser/R && \
    mv transmart-data/Makefile /home/ruser/Makefile && \
    mv transmart-data/makefile.inc /home/ruser/makefile.inc && \
    rm -rf /home/ruser/transmart-data/* && \
    rm transmart-data/.gitignore transmart-data/.travis.yml && \
    mv /home/ruser/R transmart-data/ && \
    mv /home/ruser/Makefile transmart-data/ && \
    mv /home/ruser/makefile.inc transmart-data/

WORKDIR /home/ruser/transmart-data

ENV TABLESPACES=dummy

# Keep trying make command until we succeed, it seems downloading R packages fails regularly

# Clean up the unwanted transmart-data files
# Save only the R directory

#RUN until make -C R install_packages; do echo "Failed, retrying..."; done && \

RUN make -C R install_packages && \
    echo remote enable >> /home/ruser/transmart-data/R/Rserv_nodaemon.conf

USER root

RUN apt-get purge -y --auto-remove curl unzip make g++ ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    chown -R ruser:ruser /home/ruser/transmart-data

USER ruser

WORKDIR /home/ruser/transmart-data/R

EXPOSE 6311

# Should add a volume for the logfile output

ENTRYPOINT ["/home/ruser/transmart-data/R/root/lib/R/bin/R","CMD","Rserve.dbg","--no-save","--RS-conf","/home/ruser/transmart-data/R/Rserv_nodaemon.conf"]
