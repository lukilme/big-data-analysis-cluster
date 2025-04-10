schematool -dbType mysql -initSchema --verbose
echo "action 1"
hive --service metastore &
sleep 5
echo "action 2"
hive --service hiveserver2
sleep 30
#beeline -u "jdbc:hive2://localhost:10000" -n "hive" -p "hivepw"