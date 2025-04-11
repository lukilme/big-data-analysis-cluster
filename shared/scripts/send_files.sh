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