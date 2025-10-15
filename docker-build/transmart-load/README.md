# tranSMART Loader Docker Image
This Dockerfile builds the Docker image that contains the tranSMART study loader(s). It requires a copy of Pentaho PDI and the transmart-data scripts. 

## Using
There are two ways to use this image:

1. Logging into the running container and executing the transmart-data makefiles:
```sh
docker run -ti --rm --network transmart -v /app/transmart/transmart-docker/studies/[STUDY_DIR]:/home/tmload/transmart-data/samples/studies/[STUDY_DIR] -e JAVAMAXMEM='4096' kretzlerdevs/transmart-load:1.0 /bin/bash
```
```
sudo bash -c "export PENTAHO_DI_JAVA_OPTIONS="-Xmx2g" && export _JAVA_OPTIONS=-Xmx8G && source ./vars && make -C samples/postgres load_clinical_Neptune_V36"
```

2. OR, create a custom loading shell script that sets the Kettle parameters accordingly. Run by invoking this image and mount the folder 
with the study as "/my_study" and execute the custom load script:

```
sudo docker run -t --rm --network transmart-docker_transmart -v /app/transmart/transmart-docker/studies/NEPTUNE_v36:/my_study -e JAVAMAXMEM='4096' transmartfoundation/transmart-load:new bash /my_study/load_clinical.sh
```

Example shell script to load clinical data:

```
set -x
$KITCHEN -norep=Y -file=/home/tmload/transmart-data/env/transmart-etl/Kettle/postgres/Kettle-ETL/create_clinical_data.kjb  \
-param:COLUMN_MAP_FILE=colmapping_v36.txt \
-param:WORD_MAP_FILE=wordmapping_v36.txt \
-param:DATA_LOCATION=/my_study/clinical \
-param:HIGHLIGHT_STUDY=N \
-param:SQLLDR_PATH=/usr/bin/psql \
-param:LOAD_TYPE=I \
-param:RECORD_EXCLUSION_FILE=x \
-param:SECURITY_REQUIRED=Y \
-param:SORT_DIR=$HOME \
-param:STUDY_ID=MY_STUDY \
-param:WORD_MAP_FILE=x \
-param:TOP_NODE='\Private Studies\Neptune_V36\'
```
