name := "spark-hive-example"

version := "0.1"

scalaVersion := "2.12.18"

libraryDependencies ++= Seq(
  "org.apache.spark" %% "spark-core" % "3.3.4",
  "org.apache.spark" %% "spark-sql"  % "3.3.4",
  "org.apache.spark" %% "spark-hive" % "3.3.4",
  "org.apache.spark" %% "spark-mllib" % "3.3.4" ,
  "org.apache.hadoop" % "hadoop-client" % "3.3.4",
  "mysql" % "mysql-connector-java" % "8.0.33"
)
