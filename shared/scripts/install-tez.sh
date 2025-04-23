#!/bin/bash

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Este script deve ser executado como root ou com sudo."
    exit 1
fi

TEZ_VERSION="0.9.2"
TEZ_HOME="/opt/tez"
HADOOP_HOME="${HADOOP_HOME:-}"
HIVE_HOME="${HIVE_HOME:-}"
HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
HIVE_CONF_DIR="${HIVE_HOME}/conf"
HDFS_TEZ_DIR="/apps/tez/${TEZ_VERSION}"
TEZ_TARBALL="apache-tez-${TEZ_VERSION}-bin.tar.gz"
TEZ_URL="https://downloads.apache.org/tez/${TEZ_VERSION}/${TEZ_TARBALL}"

if [ -z "$HADOOP_HOME" ]; then
    echo "Erro: HADOOP_HOME não está definido."
    exit 1
fi
if [ -z "$HIVE_HOME" ]; then
    echo "Erro: HIVE_HOME não está definido."
    exit 1
fi

echo "Baixando Apache Tez ${TEZ_VERSION}..."
wget -q "$TEZ_URL" -O "/tmp/${TEZ_TARBALL}"
echo "Instalando em ${TEZ_HOME}..."
rm -rf "$TEZ_HOME" && mkdir -p "$TEZ_HOME"
tar -xzf "/tmp/${TEZ_TARBALL}" -C "$TEZ_HOME" --strip-components=1

echo "Deploy no HDFS em ${HDFS_TEZ_DIR}..."
su - hadoop -c "hdfs dfs -mkdir -p ${HDFS_TEZ_DIR}"
su - hadoop -c "hdfs dfs -copyFromLocal -f /tmp/${TEZ_TARBALL} ${HDFS_TEZ_DIR}/"

cat > "$TEZ_HOME/conf/tez-site.xml" <<EOF
<configuration>
  <property>
    <name>tez.lib.uris</name>
    <value>\${fs.defaultFS}${HDFS_TEZ_DIR}/${TEZ_TARBALL}</value>
  </property>
  <property>
    <name>tez.use.cluster.hadoop-libs</name>
    <value>false</value>
  </property>
</configuration>
EOF

cat >> "${HADOOP_CONF_DIR}/hadoop-env.sh" <<EOF

# Configuração Apache Tez
export TEZ_HOME=${TEZ_HOME}
export TEZ_CONF_DIR=\${TEZ_HOME}/conf
export TEZ_JARS=\${TEZ_HOME}/*:\${TEZ_HOME}/lib/*
export HADOOP_CLASSPATH=\${TEZ_CONF_DIR}:\${TEZ_JARS}:\${HADOOP_CLASSPATH}
EOF


cp "${HIVE_CONF_DIR}/hive-env.sh.template" "${HIVE_CONF_DIR}/hive-env.sh"
cat >> "${HIVE_CONF_DIR}/hive-env.sh" <<EOF

# Configuração Apache Tez
export HIVE_AUX_JARS_PATH=\${HIVE_AUX_JARS_PATH}:${TEZ_HOME}/*:${TEZ_HOME}/lib/*
EOF

cat >> "${HADOOP_CONF_DIR}/hadoop-env.sh" <<EOF

# Configuração Apache Tez
export HIVE_AUX_JARS_PATH=:${TEZ_HOME}/*:${TEZ_HOME}/lib/*
EOF

echo "Reiniciando HDFS e YARN..."
su - hadoop -c "${HADOOP_HOME}/sbin/stop-dfs.sh && ${HADOOP_HOME}/sbin/start-dfs.sh"
su - hadoop -c "${HADOOP_HOME}/sbin/stop-yarn.sh && ${HADOOP_HOME}/sbin/start-yarn.sh"

