#!/bin/bash
if (( $# == 0 )); then
  echo "Please enter a study name."
else
  docker run -ti --rm --network transmart -v /app/transmart/transmart-docker/studies/$1:/home/tmload/transmart-data/samples/studies/$1 -e JAVAMAXMEM='4096' kretzlerdevs/transmart-load:1.1 /bin/bash load_expression.sh $1
fi
