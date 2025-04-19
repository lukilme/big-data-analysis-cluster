spark-shell --master yarn \
            --deploy-mode client \
            --conf spark.sql.catalogImplementation=hive \
            --conf spark.hadoop.hive.metastore.uris=thrift://localhost:9083



pyspark --master yarn \
        --deploy-mode client \
        --conf spark.sql.catalogImplementation=hive \
        --conf spark.hadoop.hive.metastore.uris=thrift://localhost:9083