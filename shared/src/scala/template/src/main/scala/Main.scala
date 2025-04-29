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

    //spark.sql("SHOW DATABASES").show()

    // val data = List("Hello World", "Hello Spark", "Scala RDD Example")
    // val rdd = sc.parallelize(data)

    // val wordCounts = rdd
    //   .flatMap(_.split(" "))
    //   .map(word => (word, 1))
    //   .reduceByKey(_ + _)

    // wordCounts.collect().foreach(println)
    val ratingsSchema = "userId INT, movieId INT, rating DOUBLE, timestamp LONG"

    val ratings = spark.read
      .option("delimiter", "\t")
      .schema(ratingsSchema)
      .csv("/shared/data/ml-100k/u.data")
    
    ratings.printSchema();
    ratings.show(5, truncate = false)

    val ratingCount = ratings.count()    
    println(s"Total ratings: $ratingCount")
    
    val highRatings = ratings.filter("rating > 4.0")
    highRatings.show(10)
    
    spark.stop()  
  }
}