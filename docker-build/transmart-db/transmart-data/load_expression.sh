#!/bin/bash

echo "***********************************"
echo "You might want to run me in screen"
echo "***********************************"
echo ""

echo "Directory Name for study (ex: Neptune_V16): "
read studyName

source vars
dos2unix ./samples/studies/$studyName/expression.params
mac2unix ./samples/studies/$studyName/expression.params
dos2unix ./samples/studies/$studyName/expression/*.txt
mac2unix ./samples/studies/$studyName/expression/*.txt

PLATFORM=`sed -n '2p' samples/studies/$studyName/expression/*_Mapping.txt | cut -d ' ' -f2 | awk '{print $4}'`

PLATFORM_LOADED=`psql -d transmart -c "select exists (select platform from deapp.de_gpl_info where platform = '$PLATFORM');" -tA`
if [ $PLATFORM_LOADED = 't' ]; then
        echo "Platform already loaded, skipping platform load"
else
        nohup make -C samples/postgres load_annotation_$PLATFORM > $PLATFORM.annotation.out &
        pid=$!

	# $! gets the pid of the last command launched in the background
        wait $pid
fi

# $? contains the return code for the last background process run
returnCode=$?

if [ $returnCode = 0 ]; then
	nohup make -C samples/postgres load_expression_$studyName > $studyName.expression.out &
	echo "To see the progress of the load tail the log $studyName.expression.out"
	pid=$!
	wait $pid
else
	echo "Annotation load failed...check log.  $PLATFORM_annotation.out"
fi

returnCode=$?

if [ $returnCode != 0 ]; then
	echo "Expression load failed...check log.  $studyName.expression.out"
fi
