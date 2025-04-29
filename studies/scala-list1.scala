// Apache Spark with Scala – Practical Exercise Set (25 tasks)
// DATASET INSTRUCTIONS
// Dataset: MovieLens 100K – https://grouplens.org/datasets/movielens/100k/

// 1. Download the file `ml-100k.zip` from the link above.
// 2. Unzip it into a convenient directory, e.g. `~/datasets/ml-100k/`.
// 3. Inside the folder you will find, among others:
//  • `u.data` – ratings, tab■separated: userId, movieId, rating, timestamp
//  • `u.item` – movie metadata, pipe■separated (|): movieId, title, releaseDate, …
//  • `u.user` – user info, pipe■separated: userId, age, gender, occupation, zipCode
// 4. Suggested schemas:
//  val ratingsSchema = "userId INT, movieId INT, rating DOUBLE, timestamp LONG"
//  val moviesSchema = "movieId INT, title STRING, releaseDate STRING, videoReleaseDate STRING,
//  IMDbURL STRING, genres ARRAY<INT>"
// 5. Example: loading `u.data` in Scala:
//  val ratings = spark.read
//  .option("delimiter", "\t")
//  .schema(ratingsSchema)
//  .csv("/path/to/ml-100k/u.data")
// 6. Make sure Spark can access the path (local or HDFS/S3/OBS).
// 7. All subsequent exercises assume the dataset is available under a path you control.

// 1. Create a new `SparkSession` named `spark` in the Scala REPL or in a `Main` object.
import org.apache.spark.sql.SparkSession

val spark = SparkSession.builder()
  .appName("MovieLensAnalysis")
  .master("local[*]")
  .getOrCreate()

// 2. Load `u.data` into a DataFrame called `ratings` with the schema (userId, movieId, rating,
// timestamp).
val ratingsSchema = "userId INT, movieId INT, rating DOUBLE, timestamp LONG"

val ratings = spark.read
    .option("delimiter", "/t")
    .schema(ratingsSchema)
    .csv("/shared/data/ml-100k/u.data")

// 3. Print the schema of `ratings` and display the first 5 rows to verify the data was loaded
// correctly.

rating.printSchema()
ratings.show(5, truncate=false)

// 4. Count how many ratings exist in the dataset.

ratingCount = ratings.count()
println(s"Quantidade $ratingCount")

// 5. Filter the `ratings` DataFrame to include only ratings strictly greater than 4.0 and display
// the first 10 results.

val highRatings = ratings.filter("rating > 4.0")
highRatings.show(10)

// 6. Compute the average rating for each `movieId` and store the result in a DataFrame named
// `avgRatings`.
import org.apache.spark.sql.functions._

val avgRatings = ratings.groupBy("movieId")
  .agg(
    avg("rating").alias("avgRating"),
    count("rating").alias("ratingCount")
  )

avgRatings.show()

// 7. Load `u.item` into a DataFrame called `movies` and join it with `avgRatings` on `movieId`.

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

  moviesWithRatings.show(10)

// 8. Using the joined DataFrame, list the top 10 movies by average rating **with at least 50
// ratings**. Show the columns `title`, `avgRating`, and `ratingCount`.


val topMovies = moviesWithRatings
  .filter("ratingCount >= 50")
  .orderBy(desc("avgRating"))
  .select("title", "avgRating", "ratingCount", "releaseDate") 
  .limit(10)

topMovies.show(10, truncate = false)

// 9. Save the DataFrame from Exercise 8 in Parquet format, partitioned by `releaseYear`, to the
// path `/tmp/top_movies_parquet`.

val topMoviesWithYear = topMovies.withColumn("releaseYear", 
  substring(col("releaseDate"), 8, 4).cast("INT"))

topMoviesWithYear.write
  .partitionBy("releaseYear")
  .parquet("/tmp/top_movies_parquet")


// 10. Read the Parquet files back into a DataFrame and show how many partitions Spark created.
// Re■partition the DataFrame into 4 partitions.


val parquetDF = spark.read.parquet("/tmp/top_movies_parquet")

println(s"Original partitions: ${parquetDF.rdd.getNumPartitions}")

val repartitionedDF = parquetDF.repartition(4)
println(s"Repartitioned to: ${repartitionedDF.rdd.getNumPartitions}")

// 11. Write a Scala UDF named `ratingLevel` that returns `"low"`, `"medium"`, or `"high"` for
// ratings ≤2, >2 & ≤4, and >4 respectively. Add this as a new column to `ratings`.


val ratingLevel = udf((rating: Double) => rating match {
  case r if r <= 2 => "low"
  case r if r > 2 && r <= 4 => "medium"
  case _ => "high"
})

val ratingsWithLevel = ratings.withColumn("ratingLevel", ratingLevel(col("rating")))

// 12. Using the `ratingLevel` column, compute the distribution (count and percentage) of each
// level for the entire dataset.

val totalRatings = ratings.count()

val levelDistribution = ratingsWithLevel.groupBy("ratingLevel")
  .agg(
    count("*").as("count"),
    (count("*") / totalRatings * 100).as("percentage")
  )
  .orderBy("ratingLevel")

levelDistribution.show()

// 13. Convert the `ratings` DataFrame into a strongly■typed `Dataset[Rating]` using a case class.
// Show how many distinct users and movies there are.

case class Rating(userId: Int, movieId: Int, rating: Double, timestamp: Long)

import spark.implicits._

val ratingsDS = ratings.as[Rating]import org.apache.spark.sql.expressions.Window

val distinctUsers = ratingsDS.select("userId").distinct().count()
val distinctMovies = ratingsDS.select("movieId").distinct().count()

println(s"Distinct users: $distinctUsers, Distinct movies: $distinctMovies")

// 14. Register the `ratings` DataFrame as a temporary view and write a Spark SQL query to find
// the top 5 users who have given the most ratings.

ratings.createOrReplaceTempView("ratings_view")

val topUsers = spark.sql("""
  SELECT userId, COUNT(*) as ratingCount
  FROM ratings_view
  GROUP BY userId
  ORDER BY ratingCount DESC
  LIMIT 5
""")

topUsers.show()

// 15. Using Spark SQL window functions, for each user compute the rank of their ratings by
// timestamp (most recent = 1). Show the first 3 ranked ratings for user ID 196.

val windowSpec = Window.partitionBy("userId").orderBy(desc("timestamp"))
val rankedRatings = ratings.withColumn("rank", rank().over(windowSpec))
rankedRatings.filter("userId = 196 AND rank <= 3").show()
    
// 16. Build an ALS (Alternating Least Squares) recommendation model to predict user ratings. Use
// 80% of the data for training and 20% for testing.
// 17. Evaluate the ALS model on the test set using RMSE. Print the RMSE value.
// 18. Use `CrossValidator` to search over at least three different values of `rank` and
// `regParam` for the ALS model. Report the best parameters and corresponding RMSE.

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

// 19. Implement a **Structured Streaming** job that reads new ratings from a socket source (JSON
// lines), updates the average rating per movie in real time, and writes the results to the
// console.



// 20. Using **GraphX**, build a user similarity graph where an edge exists between two users if
// they have rated at least 10 common movies. Compute the PageRank of each user and list the top
// 10 influential users.



// 21. Create an OBS (Object Storage Service) bucket named `movielens-data-<your-id>` in Huawei
// Cloud and upload the `u.data` and `u.item` files using the OBS Console or `obsutil`. Record the
// `obs://` URI of each file.



// 22. Modify your Spark application to read the ratings and movies data directly from OBS using
// the `obs://` paths obtained in Exercise 21. Verify the row count matches the local load.



// 23. Provision a Huawei Cloud MRS (MapReduce Service) cluster with Spark 3.x, mount the OBS
// bucket created earlier, and run Exercise 8 on the cluster. Save the Parquet output back to OBS
// under `obs://<bucket>/top_movies_parquet/`.



// 24. Using Huawei Cloud DLI (Data Lake Insight) Serverless Spark, create a job that trains the
// ALS model from Exercise 16 and persists the model to OBS. Include a JSON snippet of your job
// configuration in your submission.



// 25. On the MRS cluster, create an HBase (CloudTable) table to store `userId`, `movieId`, and
// `ratingLevel` (from Exercise 11). Write a Spark job that bulk■loads the data into HBase and
// then queries the count of `high` ratings per user using the Spark■HBase connector.