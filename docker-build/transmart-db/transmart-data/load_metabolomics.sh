#!/bin/bash

echo "***********************************"
echo "You might want to run me in screen"
echo "***********************************"
echo ""

echo "Directory Name for study (ex: Neptune_V16): "
read studyName

source vars
dos2unix ./samples/studies/$studyName/metabolomics.params
mac2unix ./samples/studies/$studyName/metabolomics.params
dos2unix ./samples/studies/$studyName/metabolomics/*.txt
mac2unix ./samples/studies/$studyName/metabolomics/*.txt


# $? contains the return code for the last background process run
returnCode=$?

export PENTAHO_JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/

if [ $returnCode = 0 ]; then
	nohup make -C samples/postgres load_metabolomics_$studyName > $studyName.metabolomics.out &
	echo "To see the progress of the load tail the log $studyName.metabolomics.out"
	pid=$!
	wait $pid
else
	echo "Annotation load failed...check log.  $PLATFORM_annotation.out"
fi

returnCode=$?

if [ $returnCode != 0 ]; then
	echo "Metabolomics load failed...check log.  $studyName.metabolomics.out"
fi