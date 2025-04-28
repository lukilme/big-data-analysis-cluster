#!/bin/bash


run_as_hadoop() {
    local cmd=$1
    echo "Executando como hadoop: $cmd"
    if ! su - hadoop -c "source $HADOOP_HOME/etc/hadoop/hadoop-env.sh && $cmd"; then
        echo "Erro ao executar comando como hadoop: $cmd" >&2
        return 1
    fi
}

set -e

TEZ_VERSION="0.10.4"
TEZ_TARBALL="apache-tez-${TEZ_VERSION}-bin.tar.gz"
TEZ_URL="https://downloads.apache.org/tez/${TEZ_VERSION}/${TEZ_TARBALL}"
TEZ_INSTALL_DIR="/opt"
TEZ_HOME="${TEZ_INSTALL_DIR}/apache-tez-${TEZ_VERSION}-bin"

HADOOP_HOME="${HADOOP_HOME:-/opt/hadoop}"  
HIVE_HOME="${HIVE_HOME:-/opt/hive}"         
HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
HIVE_CONF_DIR="${HIVE_HOME}/conf"
HDFS_TEZ_DIR="/apps/"

run_as_hadoop "hdfs dfs -mkdir -p ${HDFS_TEZ_DIR}"

echo "Baixando Apache Tez..."
wget -q -P /tmp/ "${TEZ_URL}"

echo "Descompactando Tez..."
tar -xzf /tmp/${TEZ_TARBALL} -C ${TEZ_INSTALL_DIR}

echo "Publicando Tez no HDFS em ${HDFS_TEZ_DIR}..."
run_as_hadoop "hdfs dfs -mkdir -p ${HDFS_TEZ_DIR}"
run_as_hadoop "hdfs dfs -put -f /tmp/${TEZ_TARBALL} ${HDFS_TEZ_DIR}"

echo "Configurando Hive para usar o Tez..."
cp -f "${HIVE_CONF_DIR}/hive-env.sh.template" "${HIVE_CONF_DIR}/hive-env.sh"


cat >> "${HADOOP_CONF_DIR}/hadoop-env.sh" <<EOF

# Configuração Apache Tez
export TEZ_HOME=${TEZ_HOME}
export TEZ_CONF_DIR=\${TEZ_HOME}/conf
export TEZ_JARS=\${TEZ_HOME}/*:\${TEZ_HOME}/lib/*
export HADOOP_CLASSPATH=\${TEZ_CONF_DIR}:\${TEZ_JARS}:\${HADOOP_CLASSPATH}
EOF

cat >> "${HIVE_CONF_DIR}/hive-env.sh" <<EOF

# Configuração do Tez
export TEZ_HOME=${TEZ_HOME}
export HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${TEZ_HOME}/lib/*
export HIVE_AUX_JARS_PATH=${TEZ_HOME}/lib/*,${HIVE_AUX_JARS_PATH}

EOF

wget https://repo1.maven.org/maven2/org/apache/tez/tez-aux-services/0.10.4/tez-aux-services-0.10.4.jar \
  -P /opt/apache-tez-0.10.4-bin/lib/


echo "Tez instalado e configurado com sucesso."
