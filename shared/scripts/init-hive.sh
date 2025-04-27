#!/bin/bash

# Inicializar o esquema do Hive
schematool -dbType mysql -initSchema \
  --verbose 

export HADOOP_OPTS="--add-opens=java.base/java.net=ALL-UNNAMED"

hadoop_profile="/home/hadoop/.bashrc"
echo "export HIVE_AUX_JARS_PATH=/opt/tez/*:/opt/tez/lib/*" >> "$hadoop_profile"
source "$hadoop_profile"  

echo "Iniciando Hive Metastore..."
hive --service metastore > metastore.log 2>&1 &

sleep 10
if grep -q "Starting Hive Metastore Server" metastore.log; then
    echo "Metastore iniciado com sucesso."
else
    echo "Falha ao iniciar Metastore. Verifique metastore.log."
    exit 1
fi

echo "Iniciando HiveServer2..."
hive --service hiveserver2 --hiveconf hive.server2.thrift.port=10000 \
    --hiveconf hive.server2.thrift.bind.host=0.0.0.0 > hiveserver2.log 2>&1 &

sleep 15

echo "Done!"