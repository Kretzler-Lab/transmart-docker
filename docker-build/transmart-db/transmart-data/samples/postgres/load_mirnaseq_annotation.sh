#!/bin/bash

#set -x
set -e

echo "running load_mirnaseq_annotation.sh $1"

# locate this shell script, and source a generic shell script to process all params related settings
UPLOAD_SCRIPTS_DIRECTORY=$(dirname "$0")
UPLOAD_DATA_TYPE="annotation"
source "$UPLOAD_SCRIPTS_DIRECTORY/process_params.inc"

# Execute some basic checks
if [ -z "$GPL_ID" ] || [ -z "$ANNOTATION_TITLE" ] ||  [ -z "$MIRNA_TYPE" ]; then
	echo "Following variables need to be set:"
        echo "    GPL_ID=$GPL_ID"
	echo "    ANNOTATION_TITLE=$ANNOTATION_TITLE"
	echo "    MIRNA_TYPE=$MIRNA_TYPE"
    	exit 1
fi

if [ "$MIRNA_TYPE" != "MIRNA_SEQ" ]; then
    echo "mirnaqpcr annotation value of \$MIRNA_TYPE '$MIRNA_TYPE' expected 'MIRNA_SEQ'"
    exit 1
fi

if [ ! -d logs ] ; then mkdir logs; fi

# Is the platform already uploaded?
ALREADY_LOADED=`$PGSQL_BIN/psql -c "select exists \
                (select platform from deapp.de_gpl_info where platform = '$GPL_ID')" -tA`
if [ $ALREADY_LOADED = 't' ]; then
    echo -e "\e[33mWARNING\e[m: Platform $GPL_ID already loaded; skipping" >&2
    exit 0
fi

# Start the upload
$KITCHEN -norep -version                                                      \
	 -file="$KETTLE_JOBS/load_qpcr_mirna_annotation.kjb"                  \
         -level="$KETTLE_LOG_LEVEL"                                           \
	 -logfile="$PWD"/logs/load_mirna_annotation_$(date +"%Y%m%d%H%M").log \
	 -param:ANNOTATION_TITLE="$ANNOTATION_TITLE"                          \
	 -param:DATA_LOCATION="$DATA_LOCATION"                                \
	 -param:GPL_ID="$GPL_ID"                                              \
	 -param:LOAD_TYPE=I                                                   \
	 -param:MIRNA_TYPE="$MIRNA_TYPE"                                      \
	 -param:SORT_DIR=/tmp
