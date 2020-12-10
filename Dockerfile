FROM docker.dbc.dk/dbc-solr8-base

COPY --chown=solr conf/conf/solrconfig.xml server/resources
COPY --chown=solr conf/conf/managed-schema server/resources
COPY --chown=solr conf/conf/lang server/resources/lang
COPY --chown=solr conf/conf/protwords.txt server/resources
COPY --chown=solr conf/conf/synonyms.txt server/resources
COPY --chown=solr conf/conf/stopwords.txt server/resources

# make a core called simple-search
RUN mkdir -p server/solr/simple-search/conf  && \
	touch server/solr/simple-search/core.properties

COPY --chown=solr conf/conf/params.json server/solr/simple-search/conf
COPY --chown=solr data server/solr/simple-search/data
COPY --chown=solr start.sh start.sh

ENV HEAPSIZE 4g
CMD ["./start.sh"]

EXPOSE 8983

LABEL DATA_URL url for data tar package
