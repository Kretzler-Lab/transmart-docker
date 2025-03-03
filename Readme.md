Table of Contents
=================
- [Usage](#usage)
- [Running a local instance](#running-a-local-instance)
- [Components](#components)
- [Upgrading](#upgrading)
- [Loading public datasets](#loading-public-datasets)
- [Copy data from an existing instance](#copy-data-from-an-existing-instance)
- [Loading your own studies](#loading-your-own-studies)

transmart-docker
================

The purpose of this repository is to provide a Docker-based
installation of TranSMART. Since TranSMART consists of multiple
services, `docker-compose` is used to build images for the different
services and manage the links between them. Apache is used to reverse
proxy requests to the Tomcat server. This branch of the repository is
configured for tranSMART 19.1. The default settings are geared towards
deployment on a server. If you want to try TranSMART on your local
machine, please refer to the 'Running a local instance' section in
this Readme.

This repository is under development. Release-nn.n branches will be
created for each supported tranSMART version.

The original code was developed by Denny Verbeeck for the eTRIKS
project. This repository starts from the 'eTRIKS 4.0' code, identical
to tranSMART 16.3 with some additional SmartR workflows.

Usage
-----

Clone this repository to an easily accessible location on your
server. There are a few configuration files to be modified before
building the images. The first is
`transmart-app/Config.groovy`. Modify the line
```
def transmartURL      = "http://localhost/transmart"
```
to the actual URL of your server. Additionally open the file
`transmart-web/httpd-vhosts.cfg` and modify the `ServerAdmin`
directive to the e-mail address of your server administrator. It
should be sufficient now to execute `docker-compose up` in the root
directory of the repository. This will automatically download all the
necessary components, create the network and volumes and run the
containers. When you see a line like this

```
tmapp_1     | INFO: Server startup in 40888 ms
```

this means the services are up and running. Verify this by running `docker-compose ps`:

```
$ docker-compose ps
           Name                         Command               State                  Ports
---------------------------------------------------------------------------------------------------------
transmartdocker_tmapp_1      catalina.sh run                  Up       127.0.0.1:8009->8009/tcp, 8080/tcp
transmartdocker_tmdb_1       /usr/lib/postgresql/14/bi ...    Up       127.0.0.1:5432->5432/tcp
transmartdocker_tmload_1     echo Use the make commands ...   Exit 0
transmartdocker_tmrserve_1   /home/ruser/transmart-data/R/root/lib ...   Up       6311/tcp
transmartdocker_tmsolr_1     java -jar start.jar              Up       8983/tcp
transmartdocker_tmweb_1      httpd-foreground                 Up       
```

This overview gives us a lot of information. We can see all services
except for `tmload` are up and running (more on `tmload` later).
We also see that port 5432 of our own machine is forwarded to port 5432
of the `tmdb` container, and that port 8009 is forwarded to port 8009
of the `tmapp` container. Exposing the database port to the localhost
allows us to connect to it using tools like `psql`. Port 8009 is used
by the `tmweb` container to proxy requests to the web application over
the `ajp` protocol. Point your browser to your server URL to see your
installation running. By default you can log in with username and
password admin. Change the password for the admin user as soon as
possible.

After your first `docker-compose up` command, use `docker-compose
stop` and `docker-compose start` to stop and start the TranSMART
stack. Using `docker-compose down` will delete all containers and the
network as well. For a full clean-up, use `docker-compose down -v`,
***this will remove named volumes as well***, essentially deleting the
TranSMART database.

It is advisable to tune some Postgres settings based on your
hardware. There is a script included in the image that sets sensible
defaults based on your hardware configuration. You can run the script
by executing
```
docker exec transmartdocker_tmdb_1 /usr/bin/tunepgsql.sh
```
Restart the container to apply the settings:
```docker restart transmartdocker_tmdb_1```

Running a local instance
------------------------

If you want to run this setup on your own machine instead of a server,
it will be more convenient to have the application be served to a
non-priviliged port. For most setups, it will be sufficient to change
the `tmweb` service block to the following:
```
  tmweb:
    image: httpd:alpine
    restart: unless-stopped
    ports:
      - "127.0.0.1:8888:80"
    depends_on:
      - tmapp
    volumes:
      - "./transmart-web/httpd-vhosts.conf:/usr/local/apache2/conf/extra/httpd-vhosts.conf"
      - "./transmart-web/httpd.conf:/usr/local/apache2/conf/httpd.conf"
```

You can now go back to following the instructions in the 'Usage' section.

Components
----------

This `docker-compose` project consists of the following services:
  - `tmweb`: httpd frontend and reverse-proxy for tomcat.
    This container is connected to the `host` network.
    This allows to see the actual client IPs in the Apache logs rather than the IP of the docker bridge.
  - `tmapp`: the tomcat server and application, with gwava and the online tranSMART manual
  - `tmdb`: the Postgres database, the database in this image has a superadmin
    with username transmartadmin and password transmart
  - `tmsolr`: the SOLR installation for faceted search,
  - `tmrserve`: Rserve instance for advanced analyses and,
  - `tmload`: a Kettle installation you can use for loading data.

Upgrading
---------

For all services except `tmapp` it is sufficient to modify the tag in
the `docker-compose` file (or pulling a new version of the file from
this repository), and executing `docker-compose up -d` again. Compose
will auto-detect which services should be recreated. For `tmapp` we
need to do a bit more work. This is because the exploded WAR file is
also kept in a volume, since it needs to be shared with the `tmrserve`
service. Before we can remove the volume, we'll need to remove the
containers using it by running `docker-compose rm -f tmapp
tmrserve`. Delete the volume by executing `docker volume rm
transmartdocker_appwebapps`. Afterwards we can run `docker-compose up
-d` again and Compose will recreate the volume and containers for us.

Loading public datasets
-----------------------

> Note: If you plan on copying an existing TranSMART database to your
  new docker-based one, please do this first, it is explained in the
  next section.

You can use the `tmload` image to load data to the database through
Kettle. The `tmload` image is built by `docker-compose`, but does not
run continuously. Instead, you should start a container based on this
image every time you want to load data. The easiest way of loading
public datasets is using the pre-curated library hosted by the
TranSMART foundation. For more information, please read their [wiki
page](https://wiki.transmartfoundation.org/display/transmartwiki/Curated+Data).
All environment variables have already been set in the `tmload` image. The
following command will fire up a new container based on the tmload
image, load the clinical data of the GSE14468 study curated by
Elevada, and remove the container after the command is completed:
```
$ docker-compose run --rm tmload make -C samples/postgres load_clinical_ElevadaGSE14468
```

Copy data from an existing instance
-----------------------------------

If you have an existing instance of TranSMART running, you may want to
copy the database to your new dockerized instance. It is best you do
this to an empty, but initialized TranSMART database, since everything
will be copied, including things like sequence values. The most
portable way of copying is using `pg_dump` to dump all data from the
old database in the form of attribute inserts, and use this file to
load data into the new database. Using the `--attribute-inserts`
option ensures that a single failed insertion (e.g. a row that exists
in the new database, like the definition of the admin user) does not
cause the whole table not to be loaded. It also guards against minor
schema changes, such as a column with default value that was added to
an existing table. On the host where the old database resides, log in
as the `postgres` user (or any other means that allows you access to
the database) and execute the following:

```sh
pg_dump -a --disable-triggers --attribute-inserts transmart | gzip > tmdump.sql.gz
```

Depending on the size of your database, this can take some time. When
the command is finished, you will have a file called
`tmdump.sql.gz`. This is the compressed file containing all SQL
statements necessary to restore your database. Copy this file to the
host running the `transmart-db` container. The default configuration
exposes port 5432 of the container to localhost, so you should be able
to connect to it. Use the following command to unzip the file and
immediately send the SQL commands to the database:

```sh
zcat tmdump.sql.gz | psql -h 127.0.0.1 -U transmartadmin transmart
```

You will be asked for the password, which is transmart. After the command
finishes, you should have all your old data in your new TranSMART
server!

Loading your own studies
------------------------
1. Start a screen session
2. Put the study folder in [transmart-docker]/studies
3. Start the load container with the study directory mounted inside and attach:
```sh
docker run -ti --rm --network transmart-docker_transmart -v /app/transmart/transmart-docker/studies/[STUDY_DIR]:/home/tmload/transmart-data/samples/studies/[STUDY_DIR] -e JAVAMAXMEM='4096' kretzlerdevs/transmart-load:1.0 /bin/bash
```
For example:
```sh
docker run -ti --rm --network transmart-docker_transmart -v /app/transmart/transmart-docker/studies/NEPTUNE_v36:/home/tmload/transmart-data/samples/studies/Neptune_V36 -e JAVAMAXMEM='4096' kretzlerdevs/transmart-load:1.0 /bin/bash
```
5. Once inside the container, navigate to transmart-data directory and run the usual load script, but as sudo, e.g. 
```sh
   sudo bash -c "source ./vars && make -C samples/postgres load_clinical_Neptune_V36"
```
6. If the above command doesn't work, you will need to increase the memory that Java has access to. 
```
sudo bash -c "export PENTAHO_DI_JAVA_OPTIONS="-Xmx2g" && export _JAVA_OPTIONS=-Xmx8G && source ./vars && make -C samples/postgres load_clinical_Neptune_V36"
```

## Loading tooltips
1. Copy the tooltip file from the study directory into the transmart database container
```
sudo docker cp ./Neptune_vXX/Node_data_definitions_vXX.csv transmart-docker-tmdb-1:/
```

2. Step inside of the container
```
docker exec -it transmart-docker-tmdb-1 bash
```

3. Open transmart database
```
psql transmart
```

4. Run add_tooltips function
```
SELECT i2b2metadata.add_tooltips('/Node_data_definitions_vXX.csv', FALSE, FALSE);
```
5. Verify 0 rows were affected
```
 add_tooltips 
--------------
(0 rows)
```