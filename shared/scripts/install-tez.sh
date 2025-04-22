#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Este script deve ser executado como root ou com sudo."
    exit 1
fi

TEZ_VERSION="0.9.2"
TEZ_HOME="/opt/tez"
HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
TEZ_TARBALL="apache-tez-${TEZ_VERSION}-bin.tar.gz"
TEZ_URL="https://downloads.apache.org/tez/${TEZ_VERSION}/${TEZ_TARBALL}"

if ! command -v wget &> /dev/null; then
    echo "wget não encontrado. Instalando..."
    apt-get update && apt-get install -y wget
fi

if [ -z "${HADOOP_HOME}" ]; then
    echo "HADOOP_HOME não está configurado. Verifique a instalação do Hadoop."
    exit 1
fi

echo "Baixando Apache Tez ${TEZ_VERSION}..."
wget "${TEZ_URL}" -P /tmp

if [ ! -f "/tmp/${TEZ_TARBALL}" ]; then
    echo "Erro no download do Apache Tez!"
    exit 1
fi

echo "Instalando em ${TEZ_HOME}..."
mkdir -p "${TEZ_HOME}"
tar -xzf "/tmp/${TEZ_TARBALL}" -C "${TEZ_HOME}" --strip-components=1
tar -xzf /tmp/apache-tez-${TEZ_VERSION}-bin.tar.gz
tar -czf /tmp/apache-tez-${TEZ_VERSION}-bin-nodir.tar.gz \
    -C apache-tez-${TEZ_VERSION}-bin .
echo 'export HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${TEZ_HOME}/*:${TEZ_HOME}/lib/*' >> "${HADOOP_CONF_DIR}/hadoop-env.sh"

echo "Configurando HDFS..."
su - hadoop -c "hdfs dfs -mkdir -p /apps/tez"
su - hadoop -c "hdfs dfs -put /tmp/apache-tez-${TEZ_VERSION}-bin-nodir.tar.gz /apps/tez/"
su - hadoop -c "hdfs dfs -put /shared/data/data.json /user/"
su - hadoop -c "hdfs dfs -chmod -R 755 /apps/tez"

touch $HADOOP_CONF_DIR/tez-site.xml

echo "Criando tez-site.xml..."
cat > "${HADOOP_CONF_DIR}/tez-site.xml" << EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>tez.lib.uris</name>
    <value>hdfs://namenode:9000/apps/tez/apache-tez-${TEZ_VERSION}-bin-nodir.tar.gz</value>
  </property>
  <property>
    <name>tez.use.cluster.hadoop-libs</name>
    <value>true</value>
  </property>
</configuration>
EOF

echo "Configurando variáveis de ambiente..."
echo "export TEZ_HOME=${TEZ_HOME}" >> "${HADOOP_CONF_DIR}/hadoop-env.sh"

#rm "/tmp/${TEZ_TARBALL}"

echo "Instalação do Apache Tez concluída!"
echo "Reinicie os serviços do Hadoop para aplicar as mudanças."
su - hadoop -c "$HADOOP_HOME/sbin/stop-yarn.sh"
su - hadoop -c "$HADOOP_HOME/sbin/start-yarn.sh"
cp $HIVE_HOME/conf/hive-env.sh.template $HIVE_HOME/conf/hive-env.sh
echo "export HIVE_AUX_JARS_PATH=$HIVE_AUX_JARS_PATH:/opt/tez/*:/opt/tez/lib/*" >> "${HIVE_HOME}/conf/hive-env.sh"
#mv /opt/tez/lib/slf4j-reload4j-1.7.36.jar /opt/tez/lib/slf4j-reload4j-1.7.36.jar.bak
#wget https://repo1.maven.org/maven2/org/apache/htrace/htrace-core/3.1.0-incubating/htrace-core-3.1.0-incubating.jar -P /opt/hive/lib/

#rm -f /opt/hive/lib/htrace-core-*.jar /opt/tez/lib/htrace-core-*.jar
#cp $HADOOP_HOME/share/hadoop/common/*.jar /opt/hive/lib/


