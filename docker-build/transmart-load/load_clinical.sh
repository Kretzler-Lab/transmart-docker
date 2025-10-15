#!/bin/bash
/bin/bash set_db_host.sh 
cd transmart-data
echo tmpassword | sudo -S bash -c "export PENTAHO_DI_JAVA_OPTIONS="-Xmx2g" && export _JAVA_OPTIONS=-Xmx8G && source ./vars && echo $PGHOST $COMMON_DB_SERVER && make -C samples/postgres load_clinical_$1"
