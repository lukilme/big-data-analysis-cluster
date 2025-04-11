CREATE DATABASE dwd;

USE dwd;

CREATE TABLE IF NOT EXISTS dwd_login(
    id BIGINT COMMENT 'ID message',
    host STRING COMMENT 'Host message',
    time_msg BIGINT COMMENT 'Time message',
    method STRING COMMENT 'Method HTTP',
    url STRING COMMENT 'Endpoint request',
    response STRING COMMENT 'Response HTTP Code',
    bytes INT COMMENT 'Message bytes'
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ("skip.header.line.count"="1");

DESCRIBE dwd_login;

LOAD DATA INPATH '/user/data.csv' INTO TABLE dwd_login;


-- 1. Total logins ever: Write a query that returns a single number: the total amount of rows
-- in dwd_login.

SELECT COUNT(*) AS total_logins FROM dwd_login;

-- 2. Daily login count (ascending): List each calendar day (yyyy-MM-dd) and the number of
-- logins on that day, ordered chronologically.

CREATE TABLE IF NOT EXISTS dwd_login_date
STORED AS PARQUET -- Formato colunar para melhor performance
AS
SELECT 
    id,
    host,
    TO_DATE(FROM_UNIXTIME(time_msg)) AS login_date, -- Alias explícito
    method,
    url,
    response,
    bytes
FROM dwd_login;

SELECT time_msg, COUNT(*) AS total_login
FROM dwd_login_date 
GROUP BY time_msg 
ORDER BY total_login DESC;

--Best answer:
SELECT 
    login_date,
    COUNT(*) AS total_login
FROM (
    SELECT 
        TO_DATE(FROM_UNIXTIME(time_msg)) AS login_date
    FROM dwd_login
) AS converted_dates
GROUP BY login_date
ORDER BY login_date ASC;

-- 3. Distinct users per day: For every day, show how many unique user_id's logged in. Sort
-- by the day with the highest distinct-user count first.

-- 4. Average logins per user (whole table): Produce one row showing the average number of
-- logins each user generated across the full dataset, rounded to two decimals.

-- 5. Hourly distribution on a given date: For 2024-01-01 only, output hour_of_day (0-23) and
-- total logins in that hour.

-- 6. 'Heavy' devices: Return all device_id's that have more than 5 logins overall, along
-- with their login counts, ordered descending.

-- 7. User totals with ranking: Build a result set containing user_id, total_login_count, and
-- their rank (1 = most logins) using ROW_NUMBER().

-- 8. Top-10 most active users: Using any window function you like, list the 10 users with
-- the highest login counts and sort them from least to most logins.

-- 9. Logins-to-device ratio by day: For every day, calculate total logins ÷ distinct
-- devices, rounded to two decimals. Return the day and the ratio.

-- 10. Bucket devices by activity: Produce one row with three columns showing how many
-- devices fall into these buckets: 1-5 logins, 6-10 logins, 11+ logins.

-- 11. Hourly percentage of a day: For 2024-01-01, display each hour, its login count, and
-- the percentage that hour represents of the day's total (two-decimal precision).

-- 12. Cumulative hourly logins: Again for 2024-01-01, output each hour and a running total
-- of logins from midnight up to that hour.

-- 13. Device with most logins per day: For each day, return the single device_id that logged
-- in the most along with its count (ties are acceptable).

-- 14. Daily Top-3 devices: Extend the previous task: list the three busiest devices per day,
-- ordered by day then by descending count.

-- 15. Users active 3 consecutive days: Count how many users logged in on three straight
-- calendar days at least once.

-- 16. 7-day moving average: For every day, compute the average number of logins across the
-- current day and the preceding six days (inclusive). Show day and average.

-- 17. User session span: For each user_id, show the number of days between their first and
-- last login (inclusive).

-- 18. Efficiency rank: For every user, calculate average daily logins per distinct device
-- and rank users by this metric (1 = highest).

-- 19. Monthly P90 of daily logins: For each month, find the 90th percentile of that month's
-- daily login counts. Return month and p90_logins.

-- 20. Dormant devices: Identify devices whose last recorded login is at least 30 days before
-- the latest date in the table. List the device and its last login timestamp.