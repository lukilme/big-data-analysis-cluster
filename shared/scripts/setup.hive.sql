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