export TEZ_HOME=${TEZ_HOME}
export HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${HADOOP_HOME}/share/hadoop/common/*:${HADOOP_HOME}/share/hadoop/common/lib/*:${HADOOP_HOME}/share/hadoop/hdfs/*:${HADOOP_HOME}/share/hadoop/hdfs/lib/*:${TEZ_HOME}/*:${TEZ_HOME}/lib/*
export HIVE_AUX_JARS_PATH=${TEZ_HOME}/lib/*,${HIVE_AUX_JARS_PATH}
