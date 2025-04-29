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

SET hive.execution.engine=tez;            
SET mapreduce.map.memory.mb=4096;        
SET mapreduce.map.java.opts=-Xmx3072m;    

SET hive.tez.container.size=4096;
SET hive.tez.java.opts=-Xmx3072m;

INSERT OVERWRITE TABLE dwd_login
SELECT
  from_unixtime(ts)       AS login_time,
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
  from_unixtime(registration) AS registration,
  gender,
  artist,
  song,
  length
FROM ods.ods_login;



-- 1. Compute the total number of logins for every calendar day 
-- in the dataset and list the five days with the highest totals.


-- 2. For each calendar day, find the distinct count of devices 
-- and rank the days from most to fewest active devices.


-- 3. Calculate the overall average number of logins per active device (distinct device_id) across
-- the entire dataset, rounded to two decimals.


-- 4. List the top 10 users who have the greatest total number of logins, ordered by the smallest
-- totals first.


-- 5. Classify devices by total login counts into buckets (1–5, 6–10, 11+) and output the number
-- of devices in each bucket.


-- 6. For 1■January■2024, determine the percentage distribution of logins across each hour of the
-- day (00–23).


-- 7. Produce a cumulative sum of logins by hour for 1■January■2024 so that each row shows the
-- running total up to that hour.


-- 8. For every calendar day, identify the three devices with the highest login counts. Break ties
-- by device_id ascending.


-- 9. Count how many users logged in on three consecutive calendar days at least once during the
-- entire observation window.


-- 10. Build a 7■day rolling average of daily distinct user counts and list the result for every
-- day after the first 6 days.


-- 11. Compute, for each month, the median daily login count (50th percentile) and the 95th
-- percentile of daily login counts.


-- 12. Find the day in the past 90 days (relative to the latest login_time) that has the highest
-- ratio of total logins to distinct users.


-- 13. Detect outlier days where total logins exceed the 30■day moving average by more than 3
-- standard deviations.


-- 14. For every device, calculate the variance of its daily login counts and list the 10 devices
-- with the highest variance.


-- 15. Build weekly cohorts based on a user’s first login week (ISO week). For each cohort,
-- compute the retention matrix for weeks 0–4.


-- 16. For each user, output the length of their longest streak of consecutive active days and
-- rank users by streak length descending.


-- 17. Compute a histogram of logins by hour_of_day (0–23) across the full dataset and report the
-- mode hour (most logins).


-- 18. Identify users who, on any single day, logged in from more than three distinct devices;
-- list the user_id, the date, and the device count.


-- 19. Define a session as a series of logins from the same device where consecutive logins are at
-- most 30 minutes apart. Calculate the average session length per device and list the five
-- devices with the longest average session length.


-- 20. Categorize users based on their longest consecutive■day streak: 1–3 days, 4–7 days, and 8+
-- days. Return the count of users in each category.


-- 21. Using collect_set, build the set of distinct device_ids per user for each calendar month,
-- then compute the Jaccard similarity between consecutive months' sets for every user. List the
-- 10 users with the lowest similarity (largest change) along with the month pair and similarity
-- score.


-- 22. For each hour_of_day (0–23), calculate the 99th percentile of per■device login counts
-- across all devices. Identify and list the hours where this percentile is more than twice the
-- median of these 99th■percentile values.


-- 23. For every ISO week, create a three■stage funnel: • Stage■A – users with at least one
-- login that week • Stage■B – users with logins on ≥3 distinct days that week • Stage■C –
-- users with logins from ≥5 distinct devices that week Output the weekly conversion rates A→B
-- and B→C for the latest 12 weeks in the dataset.


-- 24. Identify "super■bursty" devices: those whose maximum daily login count is at least 10×
-- their median daily login count and where this burst occurred within the last 30 days of data.
-- Return device_id, burst_date, burst_count, and median_count, ordered by burst_count descending.


-- 25. Using a sliding 180■day window, compute a z■score for each day's total login count (value
-- minus mean divided by standard deviation of the window). Flag days where |z|■>■4 as extreme
-- anomalies and list them chronologically with their z■scores.