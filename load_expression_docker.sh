#!/bin/bash
if [ -z "$2" ]; then
  echo "Usage: $0 <study name> <app num>"
  exit 1
fi

if [ "$2" -eq 1 ]; then
  echo "Loading $1 into app 1."
  PGHOST=tmdb
elif [ "$2" -eq 2 ]; then
  echo "Loading $1 into app 2."
  PGHOST=tmdb-app2
else
  echo "Loading $1 into app 1."
  PGHOST=tmdb
fi
docker run -ti --rm -e PGHOST=$PGHOST --network transmart -v /app/transmart/transmart-docker/studies/$1:/home/tmload/transmart-data/samples/studies/$1 -e JAVAMAXMEM='4096' kretzlerdevs/transmart-load:1.1 /bin/bash load_expression.sh $1
