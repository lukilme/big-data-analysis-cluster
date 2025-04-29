import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.expressions.Window
import org.apache.spark.ml.recommendation.{ALS, ALSModel}
import org.apache.spark.ml.evaluation.RegressionEvaluator
import org.apache.spark.ml.tuning.{CrossValidator, ParamGridBuilder}
import org.apache.spark.sql.DataFrame

case class Rating(userId: Int, movieId: Int, rating: Double, timestamp: Long)

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


    val avgRatings = ratings.groupBy("movieId")
      .agg(
        avg("rating").alias("avgRating"),
        count("rating").alias("ratingCount")
      )

    avgRatings.show()

    val moviesSchema = "movieId INT, title STRING, releaseDate STRING, videoReleaseDate STRING, " +
      "IMDbURL STRING, unknown INT, Action INT, Adventure INT, Animation INT, " +
      "Children INT, Comedy INT, Crime INT, Documentary INT, Drama INT, Fantasy INT, " +
      "FilmNoir INT, Horror INT, Musical INT, Mystery INT, Romance INT, SciFi INT, " +
      "Thriller INT, War INT, Western INT"

    val movies = spark.read
      .option("delimiter", "|")
      .schema(moviesSchema)
      .csv("/shared/data/ml-100k/u.item")

    var moviesWithRatings = movies.join(avgRatings, "movieId")

    moviesWithRatings = moviesWithRatings.sort(col("ratingCount").desc)

    val topMovies = moviesWithRatings
      .filter("ratingCount >= 50")
      .orderBy(desc("avgRating"))
      .select("title", "avgRating", "ratingCount", "releaseDate") 
      .limit(10)

    topMovies.show(10, truncate = false)
    
    val topMoviesWithYear = topMovies.withColumn("releaseYear", 
      substring(col("releaseDate"), 8, 4).cast("INT"))

    // topMoviesWithYear.write
    //   .partitionBy("releaseYear")
    //   .parquet("/tmp/top_movies_parquet")

    topMoviesWithYear.show(5)

    import spark.implicits._

  
    val parquetDF = spark.read.parquet("/tmp/top_movies_parquet")

    println(s"Original partitions: ${parquetDF.rdd.getNumPartitions}")

    val repartitionedDF = parquetDF.repartition(4)
    println(s"Repartitioned to: ${repartitionedDF.rdd.getNumPartitions}")

    val ratingLevel = udf((rating: Double) => rating match {
      case r if r <= 2 => "low"
      case r if r > 2 && r <= 4 => "medium"
      case _ => "high"
    })

    val ratingsWithLevel = ratings.withColumn("ratingLevel", ratingLevel(col("rating")))

    ratingsWithLevel.show(10)

    val totalRatings = ratings.count()

    val levelDistribution = ratingsWithLevel.groupBy("ratingLevel")
      .agg(
        count("*").as("count"),
        (count("*") / totalRatings * 100).as("percentage")
      )
      .orderBy("ratingLevel")

    levelDistribution.show()

    val ratingsDS = ratings.as[Rating]
    val distinctUsers = ratingsDS.select("userId").distinct().count()
    val distinctMovies = ratingsDS.select("movieId").distinct().count()

    println(s"Distinct users: $distinctUsers, Distinct movies: $distinctMovies *****************************")

    ratings.createOrReplaceTempView("ratings_view")

    val topUsers = spark.sql("""
      SELECT userId, COUNT(*) as ratingCount
      FROM ratings_view
      GROUP BY userId
      ORDER BY ratingCount DESC
      LIMIT 5
    """)
    topUsers.show()

    val windowSpec = Window.partitionBy("userId").orderBy(desc("timestamp"))

    val rankedRatings = ratings.withColumn("rank", rank().over(windowSpec))

    rankedRatings.filter("userId = 196 AND rank <= 3").show()
    // val (model, test) = buildAndTrainALSModel(ratings)
    // evaluateModel(model, test)
    spark.stop()  
  }

  def buildAndTrainALSModel(ratings: DataFrame): (ALSModel, DataFrame) = {
    val Array(training, test) = ratings.randomSplit(Array(0.8, 0.2))

    val als = new ALS()
      .setUserCol("userId")
      .setItemCol("movieId")
      .setRatingCol("rating")
      .setColdStartStrategy("drop") 

    val paramGrid = new ParamGridBuilder()
      .addGrid(als.rank, Array(5))
      .addGrid(als.regParam, Array(0.01))
      .build()

    val evaluator = new RegressionEvaluator()
      .setMetricName("rmse")
      .setLabelCol("rating")
      .setPredictionCol("prediction")

    val cv = new CrossValidator()
      .setEstimator(als)
      .setEvaluator(evaluator)
      .setEstimatorParamMaps(paramGrid)
      .setNumFolds(3) 
      .setParallelism(2) 

    val cvModel = cv.fit(training)
    val bestModel = cvModel.bestModel.asInstanceOf[ALSModel]
    
    val alsModel = bestModel.asInstanceOf[ALSModel]
    println(s"  Rank: ${alsModel.rank}")
    println(s"  RegParam: ${alsModel.explainParams}")
    println(s"  MaxIter: ${alsModel.params}")

    (bestModel, test)
  }

  def evaluateModel(model: ALSModel, testData: DataFrame): Unit = {
    val predictions = model.transform(testData)
    
    val evaluator = new RegressionEvaluator()
      .setMetricName("rmse")
      .setLabelCol("rating")
      .setPredictionCol("prediction")

    val rmse = evaluator.evaluate(predictions)
    println(s"\nRoot Mean Squared Error (RMSE) on test data: $rmse")

    println("\nSample predictions:")
    predictions.select("userId", "movieId", "rating", "prediction")
      .show(10, truncate = false)
  }
}