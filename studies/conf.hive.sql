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