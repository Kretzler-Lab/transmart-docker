#!/bin/bash

if [ -z "$1" ] || [ "$1" == "db" ]; then
echo " "
echo "Building transmart-db"
echo "====================="
cd transmart-db
(( start=SECONDS ))
docker build --no-cache --force-rm --tag transmartfoundation/transmart-db:latest . 2>&1  > build.out
(( end=SECONDS ))
(( duration=end-start ))
egrep '(^Step [0-9=+/[0-9]+)|^(Successfully)' build.out
echo "Completed in $duration seconds"
cd ..
fi

if [ -z "$1" ] || [ "$1" == "app" ]; then
echo " "
echo "Building transmart-app"
echo "======================"
cd transmart-app
(( start=SECONDS ))
docker build --no-cache --force-rm --tag transmartfoundation/transmart-app:latest . 2>&1  > build.out
(( end=SECONDS ))
(( duration=end-start ))
egrep '(^Step [0-9=+/[0-9]+)|^(Successfully)' build.out
echo "Completed in $duration seconds"
cd ..
fi

if [ -z "$1" ] || [ "$1" == "load" ]; then
echo " "
echo "Building transmart-load"
echo "======================="
cd transmart-load
(( start=SECONDS ))
docker build --no-cache --force-rm --tag transmartfoundation/transmart-load:latest . 2>&1 > build.out
(( end=SECONDS ))
(( duration=end-start ))
egrep '(^Step [0-9=+/[0-9]+)|^(Successfully)' build.out
echo "Completed in $duration seconds"
cd ..
fi

if [ -z "$1" ] || [ "$1" == "solr" ]; then
echo " "
echo "Building transmart-solr"
echo "======================="
cd transmart-solr
(( start=SECONDS ))
docker build --no-cache --force-rm --tag transmartfoundation/transmart-solr:latest . 2>&1 > build.out
(( end=SECONDS ))
(( duration=end-start ))
egrep '(^Step [0-9=+/[0-9]+)|^(Successfully)' build.out
echo "Completed in $duration seconds"
cd ..
fi

if [ -z "$1" ] || [ "$1" == "rserve" ]; then
echo " "
echo "Building transmart-rserve"
echo "========================="
cd transmart-rserve
(( start=SECONDS ))
docker build --no-cache --force-rm --tag transmartfoundation/transmart-rserve:latest . 2>&1 > build.out
(( end=SECONDS ))
(( duration=end-start ))
egrep '(^Step [0-9=+/[0-9]+)|^(Successfully)' build.out
echo "Completed in $duration seconds"
cd ..
fi

# transmart-web has no docker image, just a few files

echo "done"
