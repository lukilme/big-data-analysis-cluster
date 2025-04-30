-- Advanced HiveQL Practice – Login Analytics (25 Hardcore Exercises)
-- Dataset: Sparkify User Activity Log Data (Kaggle) Link:
-- https://www.kaggle.com/datasets/udacity/sparkify-user-activity-tracker Load 
-- the log data into a Hive table named `dwd_login` with at least the following 
-- columns: • user_id (STRING) • device_id (STRING) • login_time (TIMESTAMP) 
-- Assume that a record represents a successful user login event. 
-- Answer each of the 25 questions below using HiveQL.
CREATE DATABASE ods;
CREATE DATABASE dwd;
CREATE DATABASE ads;

USE ods;

CREATE TABLE ods_login(
    ts BIGINT,
    userId STRING,
    sessionId STRING,
    page STRING,
    auth STRING,
    method STRING,
    status INT,
    level STRING,
    itemInSession INT,
    location STRING,
    userAgent STRING,
    lastName STRING,
    firstName STRING,
    registration BIGINT,
    gender STRING,
    artist STRING,
    song STRING,
    length FLOAT
)
ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
STORED AS TEXTFILE;

LOAD DATA INPATH '/user/data.json' INTO TABLE ods_login;

USE dwd;

CREATE TABLE dwd_login(
    login_time TIMESTAMP COMMENT 'Data e hora do evento de login',
    user_id STRING COMMENT 'Identificador único do usuário',
    session_id STRING COMMENT 'Identificador da sessão do usuário',
    page STRING COMMENT 'Página acessada',
    auth STRING COMMENT 'Tipo de autenticação',
    method STRING COMMENT 'Método de requisição',
    status INT COMMENT 'Código de status HTTP retornado',
    level STRING COMMENT 'Nível de acesso do usuário',
    item_session INT COMMENT 'Índice do item na sessão',
    location STRING COMMENT 'Localização do usuário',
    user_agent STRING COMMENT 'Informações do navegador e dispositivo',
    last_name STRING COMMENT 'Sobrenome do usuário',
    first_name STRING COMMENT 'Primeiro nome do usuário',
    registration TIMESTAMP COMMENT 'Timestamp de registro do usuário',
    gender STRING COMMENT 'Gênero do usuário',
    artist STRING COMMENT 'Artista relacionado ao evento',
    song STRING COMMENT 'Música ou conteúdo acessado',
    length FLOAT COMMENT 'Duração da mídia em segundos'
)
COMMENT 'Tabela de logins detalhados no nível DWD'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

USE dwd;

SET hive.tez.container.size=4096;
SET hive.tez.java.opts=-Xmx3072m;
ADD JAR hdfs:///apps/hive/lib/hive-hcatalog-core-4.0.1.jar;
SET hive.auto.convert.join=false;

INSERT OVERWRITE TABLE dwd_login
SELECT
  from_unixtime(CAST(ts / 1000 AS BIGINT))     AS login_time,
  userId                  AS user_id,
  sessionId               AS session_id,
  page,
  auth,
  method,
  status,
  level,
  itemInSession           AS item_session,
  location,
  userAgent               AS user_agent,
  lastName                AS last_name,
  firstName               AS first_name,
  from_unixtime(CAST(registration / 1000 AS BIGINT)) AS registration,
  gender,
  artist,
  song,
  length
FROM ods.ods_login;

-- 1. Compute the total number of logins for every calendar day 
-- in the dataset and list the five days with the highest totals.
SELECT aux.day_calendar, COUNT(*) AS count_logins
FROM (
  SELECT DAY(login_time) AS day_calendar,
    user_id
  FROM dwd.dwd_login
) AS aux
GROUP BY aux.day_calendar
ORDER BY count_logins DESC
LIMIT 5;

-- 2. For each calendar day, find the distinct count of devices 
-- and rank the days from most to fewest active devices.
SELECT 
  DENSE_RANK() OVER (ORDER BY count_logins DESC) AS rank,
  day_calendar,
  count_logins
FROM (
  SELECT 
    DAY(login_time) AS day_calendar,
    COUNT(DISTINCT session_id) AS count_logins
  FROM dwd.dwd_login
  GROUP BY DAY(login_time)
) AS agg
LIMIT 10;

-- 3. Calculate the overall average number of logins per active device (distinct device_id) across
-- the entire dataset, rounded to two decimals.

SELECT ROUND(AVG(total_logins),2)
FROM (
  SELECT 
    session_id,
    COUNT(*) AS total_logins
  FROM dwd.dwd_login
  GROUP BY session_id
) AS agg;

-- 4. List the top 10 users who have the greatest total number of logins, ordered by the smallest
-- totals first.
WITH user_logins AS(
  SELECT user_id,
  COUNT(*) AS count_logins
  FROM dwd.dwd_login
  GROUP BY user_id
),total_aux AS(
  SELECT user_id,
    count_logins 
  FROM user_logins
  ORDER BY count_logins
  LIMIT 10
)
SELECT user_id, count_logins
FROM total_aux
ORDER BY count_logins ASC;

-- 5. Classify devices by total login counts into buckets (1–5, 6–10, 11+) and output the number
-- of devices in each bucket.

WITH device_counts AS (
  SELECT
    session_id,
    COUNT(*) AS aux
  FROM dwd_login
  GROUP BY session_id
)
SELECT
  CASE 
    WHEN aux BETWEEN 1 AND 5 THEN '1-5'
    WHEN aux BETWEEN 6 AND 10 THEN '6-10'
    ELSE '11+'
  END AS bucket,
  COUNT(*) AS num_devices
FROM device_counts
GROUP BY
  CASE
    WHEN aux BETWEEN 1 AND 5 THEN '1-5'
    WHEN aux BETWEEN 6 AND 10 THEN '6-10'
    ELSE '11+'
  END;


-- 6. For 1■January■2024, determine the percentage distribution of logins across each hour of the
-- day (00–23).

WITH hourly AS (
  SELECT 
    HOUR(login_time) AS hour_tour,
    COUNT(*) AS aux
  FROM dwd_login
  WHERE TO_DATE(login_time) = '2018-11-04'
  GROUP BY HOUR(login_time)
),
total AS(
  SELECT SUM(aux) AS total FROM hourly
)
SELECT
  hour_tour,
  ROUND( aux/ total.total *100,2) AS pct_distribution
FROM hourly
CROSS JOIN total
ORDER BY hour_tour;

-- 7. Produce a cumulative sum of logins by hour for 1■January■2024 so that each row shows the
-- running total up to that hour.
WITH count_by_hour AS(
  SELECT
    HOUR(login_time) AS hour,
    COUNT(*) AS cnt
  FROM dwd_login
  WHERE TO_DATE(login_time) = '2018-11-04'
  GROUP BY HOUR(login_time)
)
SELECT hour, cnt, SUM(cnt) OVER(
  ORDER BY hour
  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS cumulative_logs
FROM count_by_hour
ORDER BY hour;

-- 8. For every calendar day, identify the three devices with the highest login counts. Break ties
-- by device_id ascending.
WITH caledoscopio AS(
  SELECT
    TO_DATE(login_time) AS day,
    session_id,
    COUNT(*) AS cnt,
    ROW_NUMBER() OVER (
      PARTITION BY TO_DATE(login_time)
      ORDER BY COUNT(*) DESC, session_id ASC
    ) AS rn
  FROM dwd_login
  GROUP BY TO_DATE(login_time), session_id
)
SELECT day, session_id, cnt
FROM caledoscopio
WHERE rn <= 3
ORDER BY day, rn
LIMIT 5;

-- 9. Count how many users logged in on three consecutive calendar days at least once during the
-- entire observation window.

WITH user_days AS (
  SELECT
    user_id,
    TO_DATE(login_time) AS day
  FROM dwd_login
  GROUP BY user_id, TO_DATE(login_time)
),
sequences AS (
  SELECT
    user_id,
    day,
    LEAD(day, 1) OVER (PARTITION BY user_id ORDER BY day)  AS next_day,
    LEAD(day, 2) OVER (PARTITION BY user_id ORDER BY day)  AS next_day2
  FROM user_days
)
SELECT
  COUNT(DISTINCT user_id) AS users_3
FROM sequences
WHERE next_day  = DATE_ADD(day, 1)
  AND next_day2 = DATE_ADD(day, 2);


-- 10. Build a 7■day rolling average of daily distinct user counts and list the result for every
-- day after the first 6 days.

WITH daily_users AS (
  SELECT
    TO_DATE(login_time) AS day,
    COUNT(DISTINCT user_id) AS distinct_users
  FROM dwd_login
  GROUP BY TO_DATE(login_time)
),
rolling AS (
  SELECT
    day,
    DISTINCT_USERS,
    ROUND(
      AVG(distinct_users) OVER (
        ORDER BY day
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
      ),
      2
    ) AS rolling_avg_7day
  FROM daily_users
),
ranked AS (
  SELECT
    day,
    rolling_avg_7day,
    ROW_NUMBER() OVER (ORDER BY day) AS rn
  FROM rolling
)
SELECT day, rolling_avg_7day
FROM ranked
WHERE rn > 6
ORDER BY day
LIMIT 10;

-- 11. Compute, for each month, the median daily login count (50th percentile) and the 95th
-- percentile of daily login counts.

WITH max_dt AS (
  SELECT max(to_date(login_time)) AS latest_day FROM dwd_login
),
recent AS (
  SELECT
    to_date(login_time) AS day,
    COUNT(*) AS total_logins,
    COUNT(DISTINCT user_id) AS distinct_users
  FROM dwd_login
  WHERE to_date(login_time) >= (
    SELECT date_sub(latest_day, 90) FROM max_dt
  )
  GROUP BY to_date(login_time)
)
SELECT
  day,
  total_logins,
  distinct_users,
  ROUND(total_logins / distinct_users, 2) AS login_user_ratio
FROM recent
ORDER BY login_user_ratio DESC
LIMIT 5;


-- 12. Find the day in the past 90 days (relative to the latest login_time) that has the highest
-- ratio of total logins to distinct users.


-- 13. Detect outlier days where total logins exceed the 30■day moving average by more than 3
-- standard deviations.

SET hive.strict.checks.type.safety=false;

WITH daily AS (
  SELECT
    TO_DATE(login_time) AS day,
    COUNT(*) AS cnt
  FROM dwd_login
  GROUP BY TO_DATE(login_time)
),
stats AS (
  SELECT
    day,
    cnt,
    AVG(cnt) OVER (
      ORDER BY day
      ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS ma_30d,
    STDDEV_SAMP(cnt) OVER (
      ORDER BY day
      ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS sd_30d
  FROM daily
)
SELECT
  day,
  cnt,
  ma_30d,
  sd_30d
FROM stats
WHERE cnt > ma_30d + 3 * sd_30d
ORDER BY day;

-- 14. For every device, calculate the variance of its daily login counts and list the 10 devices
-- with the highest variance.

WITH daily_dev AS (
  SELECT
    session_id,
    to_date(login_time) AS day,
    COUNT(*)            AS cnt
  FROM dwd_login
  GROUP BY session_id, to_date(login_time)
),
var_dev AS (
  SELECT
    session_id,
    VARIANCE(cnt) AS variance_login
  FROM daily_dev
  GROUP BY session_id
)
SELECT
  session_id,
  variance_login
FROM var_dev
ORDER BY variance_login DESC
LIMIT 10;

-- 15. Build weekly cohorts based on a user’s first login week (ISO week). For each cohort,
-- compute the retention matrix for weeks 0–4.

-- WITH first_week AS (
--   SELECT
--     user_id,
--     YEAR(login_time) AS yr,
--     WEEKOFYEAR(login_time) AS cw,
--     MIN(CAST(CONCAT(YEAR(login_time), '-', WEEKOFYEAR(login_time), '-1') AS DATE))
--       OVER (PARTITION BY user_id) AS cohort_start
--   FROM dwd_login
-- ),
-- activity AS (
--   SELECT
--     f.user_id,
--     f.cw AS cohort_week,
--     YEAR(dl.login_time) AS yr2,
--     WEEKOFYEAR(dl.login_time) AS activity_week
--   FROM first_week f
--   JOIN dwd_login dl
--     ON f.user_id = dl.user_id
-- ),
-- cohort_matrix AS (
--   SELECT
--     cohort_week,
--     activity_week - cohort_week AS week_offset,
--     COUNT(DISTINCT user_id) AS retained_users
--   FROM activity
--   GROUP BY cohort_week, activity_week - cohort_week
--   HAVING week_offset BETWEEN 0 AND 4
-- )
-- SELECT
--   cohort_week,
--   week_offset,
--   retained_users
-- FROM cohort_matrix
-- ORDER BY cohort_week, week_offset;


-- 16. For each user, output the length of their longest streak of consecutive active days and
-- rank users by streak length descending.

WITH user_days AS (
  SELECT
    user_id,
    TO_DATE(login_time) AS day
  FROM dwd_login
  GROUP BY user_id, TO_DATE(login_time)
),
seq AS (
  SELECT
    user_id,
    day,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY day) AS rn
  FROM user_days
),
groups AS (
  SELECT
    user_id,
    day,
    rn,
    date_sub(day, rn) AS grp_key
  FROM seq
),
streaks AS (
  SELECT
    user_id,
    COUNT(*) AS streak_length
  FROM groups
  GROUP BY user_id, grp_key
)
SELECT
  user_id,
  MAX(streak_length) AS longest_streak
FROM streaks
GROUP BY user_id
ORDER BY longest_streak DESC
LIMIT 10;


-- 17. Compute a histogram of logins by hour_of_day (0–23) across the full dataset and report the
-- mode hour (most logins).

WITH hourly AS (
  SELECT
    hour(login_time) AS hr,
    COUNT(*)         AS cnt
  FROM dwd_login
  GROUP BY hour(login_time)
)
SELECT
  hr,
  cnt
FROM hourly
ORDER BY cnt DESC
LIMIT 1;

-- 18. Identify users who, on any single day, logged in from more than three distinct devices;
-- list the user_id, the date, and the device count.

SELECT
  user_id,
  TO_DATE(login_time) AS day,
  COUNT(DISTINCT session_id) AS device_count
FROM dwd_login
GROUP BY user_id, TO_DATE(login_time)
HAVING device_count > 3
ORDER BY user_id, day;

