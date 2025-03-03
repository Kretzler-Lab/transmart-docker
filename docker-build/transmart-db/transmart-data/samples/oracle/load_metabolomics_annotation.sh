#!/bin/bash

#set -x
set -e

echo "running load_metabolomics_annotation.sh $1"

# locate this shell script, and source a generic shell script to process all params related settings
UPLOAD_SCRIPTS_DIRECTORY=$(dirname "$0")
UPLOAD_DATA_TYPE="annotation"
source "$UPLOAD_SCRIPTS_DIRECTORY/process_params.inc"

# Execute some basic checks
if [ -z "$GPL_ID" ] || [ -z "$ANNOTATION_TITLE" ]; then
	echo "Following variables need to be set:"
        echo "    GPL_ID=$GPL_ID"
	echo "    ANNOTATION_TITLE=$ANNOTATION_TITLE"
    	exit 1
fi

if [ ! -d logs ] ; then mkdir logs; fi

cd $2

# Is the platform already uploaded?
groovy -cp "$LIB_CLASSPATH" InsertGplInfo.groovy \
	-p "$GPL_ID" \
	-t "$ANNOTATION_TITLE" \
	-m "METABOLOMICS" \
	-o "$ORGANISM" || { test $? -eq 3 && exit 0; }
# the exit code is 3 if we are to skip the rest
# due to annotation being already loaded

cd $DATA_LOCATION

# Start the upload
$KITCHEN -norep -version                                                            \
	 -file="$KETTLE_JOBS/load_metabolomic_annotation.kjb"                       \
	 -level="$KETTLE_LOG_LEVEL"                                                 \
	 -logfile="$PWD"/logs/load_metabolomic_annotation_$(date +"%Y%m%d%H%M").log \
	 -param:ANNOTATION_TITLE="$ANNOTATION_TITLE"                                \
	 -param:DATA_LOCATION="$DATA_LOCATION"                                      \
	 -param:GPL_ID="$GPL_ID"                                                    \
	 -param:LOAD_TYPE=I                                                         \
	 -param:SORT_DIR=/tmp
