source $HIVE_CONF_DIR/hive-env.sh
echo hiveserver2 starting
$HIVE_HOME/bin/hiveserver2 --service hiveserver2 &
sleep 5

echo metastore starting
$HIVE_HOME/bin/hive --service metastore &