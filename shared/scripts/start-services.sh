#!/bin/bash

service ssh start

service mysql start

if [ ! -d "/tmp/hadoop-hadoop/dfs/name" ]; then
  echo "Formatando namenode..."
  su - hadoop -c "$HADOOP_HOME/bin/hdfs namenode -format"
fi

su - hadoop -c "$HADOOP_HOME/sbin/start-dfs.sh"
su - hadoop -c "$HADOOP_HOME/sbin/start-yarn.sh"
su - hadoop -c "$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver"

su - hadoop -c "$HIVE_HOME/bin/schematool -dbType mysql -initSchema"
su - hadoop -c "nohup $HIVE_HOME/bin/hiveserver2 > /var/log/hiveserver2.log 2>&1 &"

su - hadoop -c "nohup /opt/hue/build/env/bin/supervisor > /var/log/hue.log 2>&1 &"

tail -f /dev/null