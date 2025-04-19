import org.apache.spark.sql.SparkSession

object SparkHiveExample {
  def main(args: Array[String]): Unit = {
    val spark = SparkSession.builder()
      .appName("Spark Hive Example")
      .master("local[*]")
      .config("spark.sql.warehouse.dir", "/user/hive/warehouse")
      .enableHiveSupport()
      .getOrCreate()

    val sc = spark.sparkContext

    spark.sql("SHOW DATABASES").show()

    val data = List("Hello World", "Hello Spark", "Scala RDD Example")
    val rdd = sc.parallelize(data)

    val wordCounts = rdd
      .flatMap(_.split(" "))
      .map(word => (word, 1))
      .reduceByKey(_ + _)

    wordCounts.collect().foreach(println)

    spark.stop()
  }
}