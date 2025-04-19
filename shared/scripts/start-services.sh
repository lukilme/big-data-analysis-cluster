#!/bin/bash
set -euo pipefail

mv /opt/hadoop/share/hadoop/common/lib/slf4j-reload4j-1.7.36.jar /opt/hadoop/share/hadoop/common/lib/slf4j-reload4j-1.7.36.jar.bak

start_service() {
    local service_name=$1
    if ! service "$service_name" status &>/dev/null; then
        echo "Iniciando serviço $service_name..."
        service "$service_name" start || {
            echo "Falha ao iniciar $service_name"
            return 1
        }
    else
        echo "Serviço $service_name já está em execução."
    fi
}

start_service ssh
start_service mysql

echo "Configurando /etc/hosts..."
if ! grep -q "namenode" /etc/hosts; then
    echo "127.0.0.1 localhost namenode" >> /etc/hosts
else
    echo "Entrada namenode já existe em /etc/hosts."
fi

required_vars=("HADOOP_HOME" "HIVE_HOME" "JAVA_HOME")
for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo "Erro: Variável $var não está definida." >&2
        exit 1
    fi
done

config_files=(
    "/shared/config/core-site.xml:$HADOOP_HOME/etc/hadoop/core-site.xml"
    "/shared/config/hdfs-site.xml:$HADOOP_HOME/etc/hadoop/hdfs-site.xml"
    "/shared/config/hive-site.xml:$HIVE_HOME/conf/hive-site.xml"
    "/shared/config/yarn-site.xml:$HADOOP_HOME/etc/hadoop/yarn-site.xml"
    "/shared/config/mapred-site.xml:$HADOOP_HOME/etc/hadoop/mapred-site.xml"
)

for file_pair in "${config_files[@]}"; do
    src="${file_pair%%:*}"
    dest="${file_pair##*:}"
    
    if [ -f "$src" ]; then
        echo "Copiando $src para $dest..."
        cp "$src" "$dest"
    else
        echo "Aviso: Arquivo de configuração $src não encontrado!" >&2
    fi
done

echo "Configurando hadoop-env.sh..."
HADOOP_ENV="$HADOOP_HOME/etc/hadoop/hadoop-env.sh"
HIVE_BEELINE_JAR=$(find "$HIVE_HOME/lib" -name 'hive-beeline-*.jar' | head -1)

hadoop_profile="/home/hadoop/.bashrc"
cat <<EOL > "$hadoop_profile"
export HADOOP_HOME="$HADOOP_HOME"
export HIVE_HOME="$HIVE_HOME"
export JAVA_HOME="$JAVA_HOME"
export PATH="\$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin"
EOL
chown hadoop:hadoop "$hadoop_profile"

cat <<EOL > "$HADOOP_ENV"
export JAVA_HOME="$JAVA_HOME"
export HDFS_NAMENODE_USER="hadoop"
export HDFS_DATANODE_USER="hadoop"
export HDFS_SECONDARYNAMENODE_USER="hadoop"
export YARN_NODEMANAGER_USER="hadoop"
export YARN_RESOURCEMANAGER_USER="hadoop"
export PATH="\$PATH:$HIVE_HOME/bin"
export HADOOP_CLASSPATH="\$HADOOP_CLASSPATH:/tmp/sqoop-classes"
export CLASSPATH="\$CLASSPATH:$HIVE_HOME/lib/*"
export CLASSPATH="\$CLASSPATH:$HIVE_BEELINE_JAR"
export HADOOP_CLASSPATH="\$HADOOP_CLASSPATH:$HIVE_HOME/lib/*"
EOL

if [ -d "/home/hadoop/.ssh" ]; then
    echo "Configurando permissões SSH..."
    chown -R hadoop:hadoop /home/hadoop/.ssh
    chmod 700 /home/hadoop/.ssh
    [ -f "/home/hadoop/.ssh/id_rsa" ] && chmod 600 /home/hadoop/.ssh/id_rsa
    [ -f "/home/hadoop/.ssh/id_rsa.pub" ] && chmod 644 /home/hadoop/.ssh/id_rsa.pub
    [ -f "/home/hadoop/.ssh/authorized_keys" ] && chmod 644 /home/hadoop/.ssh/authorized_keys
else
    echo "Aviso: Diretório .ssh não encontrado!" >&2
fi

su - hadoop -c "echo \$PATH"
su - hadoop -c "echo \$HADOOP_HOME"

run_as_hadoop() {
    local cmd=$1
    echo "Executando como hadoop: $cmd"
    if ! su - hadoop -c "source $HADOOP_HOME/etc/hadoop/hadoop-env.sh && $cmd"; then
        echo "Erro ao executar comando como hadoop: $cmd" >&2
        return 1
    fi
}

echo "Inicializando Hadoop..."
run_as_hadoop "hdfs namenode -format -force"
run_as_hadoop "$HADOOP_HOME/sbin/stop-dfs.sh" || true
run_as_hadoop "$HADOOP_HOME/sbin/stop-yarn.sh" || true
run_as_hadoop "$HADOOP_HOME/sbin/start-dfs.sh"
run_as_hadoop "$HADOOP_HOME/sbin/start-yarn.sh"

echo "Aguardando inicialização dos serviços..."
for i in {1..10}; do
    if run_as_hadoop "hdfs dfsadmin -report" &>/dev/null; then
        break
    fi
    echo $i;
    sleep 5
done

echo "Criando diretórios HDFS..."
run_as_hadoop "hdfs dfs -mkdir -p /tmp /user/hive/warehouse"
run_as_hadoop "hdfs dfs -chmod -R 1777 /tmp"
run_as_hadoop "hdfs dfs -chmod -R 777 /user/hive/warehouse"
run_as_hadoop "hdfs dfs -chown hive:hive /user/hive/warehouse"

run_as_hadoop "hdfs dfs -chmod -R 777 /user"
run_as_hadoop "hdfs dfs -chown root:supergroup /user"

# hdfs dfs -chmod 755 /user
# hdfs dfs -chmod -R 777 /user/hive/warehouse  
# hdfs dfs -chown -R root:supergroup /user/hive/warehouse
# hdfs dfs -chmod -R 755 /user/hive/warehouse

echo "Configuração concluída com sucesso!"

# if [ ! -d "/tmp/hadoop-hadoop/dfs/name" ]; then
#   echo "Formatando namenode..."
#   su - hadoop -c "$HADOOP_HOME/bin/hdfs namenode -format"
# fi

# su - hadoop -c "$HADOOP_HOME/sbin/start-dfs.sh"
# su - hadoop -c "$HADOOP_HOME/sbin/start-yarn.sh"
# su - hadoop -c "$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver"

# su - hadoop -c "$HIVE_HOME/bin/schematool -dbType mysql -initSchema"
# su - hadoop -c "nohup $HIVE_HOME/bin/hiveserver2 > /var/log/hiveserver2.log 2>&1 &"

# su - hadoop -c "nohup /opt/hue/build/env/bin/supervisor > /var/log/hue.log 2>&1 &"

tail -f /dev/null