#!/bin/bash

echo "***********************************"
echo "You might want to run me in screen"
echo "***********************************"
echo ""

echo "Directory Name for study (ex: Neptune_V16): "
read studyName
echo "Name of tooltips file:"
read toolTips

source vars
dos2unix ./samples/studies/$studyName/clinical.params
mac2unix ./samples/studies/$studyName/clinical.params

nohup make -C samples/postgres load_clinical_$studyName > $studyName.clinical.out &
pid=$!
wait $pid
result=$?

echo "Log file available at $studyName.clinical.out"

if [ $result = 0 ]; then
	RESULT=`psql -d transmart -c "SELECT i2b2metadata.add_tooltips('/home/transmart/transmart/transmart-data/samples/studies/$studyName/$toolTips', FALSE, FALSE);"`
	echo $RESULT
else
	echo "Clinical load failed.  Check log file $studyName.clinical.out"
fi
