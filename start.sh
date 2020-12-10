#!/usr/bin/env bash

set -xe

if test ! -z $DATA_URL; then
	echo Downloading data from $DATA_URL
	curl -L $DATA_URL -o data.tar
	tar -xf data.tar
	rm -r /opt/solr/server/solr/simple-search/data/
	mv data /opt/solr/server/solr/simple-search/data/
fi
/docker-entrypoint.sh
