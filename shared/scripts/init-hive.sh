schematool -dbType mysql -initSchema --verbose

export HADOOP_OPTS="--add-opens=java.base/java.net=ALL-UNNAMED"

echo "action 1"
hive --service metastore > metastore.log 2>&1 &

sleep 5
cat metastore.log
sleep 5
cat metstore.log
sleep 5
cat metstore.log

echo "action 2"
hive --service hiveserver2 --hiveconf hive.server2.thrift.port=10000 --hiveconf hive.server2.thrift.bind.host=0.0.0.0 > hiveserver2.log 2>&1 &
sleep 8

echo "Done!"

#beeline -u "jdbc:hive2://localhost:10000" -n "hive" -p "hivepw --verbose=true"
echo "beeline -u "jdbc:hive2://localhost:10000" -n "hive" -p "hivepw" --verbose=true"