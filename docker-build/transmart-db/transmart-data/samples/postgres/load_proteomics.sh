#!/bin/bash

#set -x
set -e

# locate this shell script, and source a generic shell script to process all params related settings
UPLOAD_SCRIPTS_DIRECTORY=$(dirname "$0")
UPLOAD_DATA_TYPE="proteomics"
source "$UPLOAD_SCRIPTS_DIRECTORY/process_params.inc"

# Check if mandatory parameter values are provided
if [ -z $DATA_FILE_PREFIX ] || [ -z "$MAP_FILENAME" ] || [ -z "$COLUMN_MAPPING_FILE" ]; then
        echo "Following variables need to be set:"
	echo "    DATA_FILE_PREFIX=$DATA_FILE_PREFIX"
	echo "    MAP_FILENAME=$MAP_FILENAME"
	echo "    COLUMN_MAPPING_FILE=$COLUMN_MAPPING_FILE"
    	exit 1
fi

SECURITY_REQUIRED=${SECURITY_REQUIRED:-N}
if [ -z "$TOP_NODE_PREFIX" ]; then
    if [ $SECURITY_REQUIRED = 'Y' ]; then
        TOP_NODE_PREFIX='Private Studies'
    else
        TOP_NODE_PREFIX='Public Studies'
    fi
fi
TOP_NODE="\\${TOP_NODE_PREFIX}\\${STUDY_NAME}\\"

TEMPDIR=$(mktemp -d -t load_acgh_XXXXXX)
trap 'rm -rf $TEMPDIR' EXIT

if [ ! -d logs ] ; then mkdir logs; fi

$PGSQL_BIN/psql -c "truncate tm_lz.lt_src_proteomics_data"
$PGSQL_BIN/psql -c "truncate tm_lz.lt_src_proteomics_subj_samp_map"
$PGSQL_BIN/psql -c "truncate tm_lz.lt_src_protein_display_mapping"
echo "Loading zone tables truncated"

$KITCHEN -norep -version                                                     \
	 -file="$KETTLE_JOBS/load_proteomics_data.kjb"                       \
	 -level="$KETTLE_LOG_LEVEL"                                          \
	 -logfile="$PWD"/logs/load_proteomics_data_$(date +"%Y%m%d%H%M").log \
	 -param:COLUMN_MAPPING_FILE="$COLUMN_MAPPING_FILE"                   \
	 -param:DATA_FILE_PREFIX="$DATA_FILE_PREFIX"                         \
	 -param:DATA_LOCATION="$DATA_LOCATION"                               \
	 -param:DATA_TYPE="$DATA_TYPE"                                       \
	 -param:INC_LOAD="$INC_LOAD"                                         \
	 -param:LOAD_TYPE=I                                                  \
	 -param:MAP_FILENAME="$MAP_FILENAME"                                 \
	 -param:SAMPLE_MAP_FILENAME="$SAMPLE_MAP_FILENAME"                   \
	 -param:SECURITY_REQUIRED="$SECURITY_REQUIRED"                       \
	 -param:SORT_DIR=/tmp                                                \
	 -param:STUDY_ID="$STUDY_ID"                                         \
	 -param:TOP_NODE="$TOP_NODE"
