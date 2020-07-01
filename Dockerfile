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

ENV HEAPSIZE 4g
CMD ["/docker-entrypoint.sh"]

EXPOSE 8983
