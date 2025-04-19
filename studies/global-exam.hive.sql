CREATE DATABASE IF NOT EXISTS ods;
CREATE DATABASE IF NOT EXISTS dw;
CREATE DATABASE IF NOT EXISTS ads;

USE ods;

CREATE TABLE t_trade_order(
    uuid STRING COMMENT 'Order Id',
    order_no STRING COMMENT 'Order No',
    orq_seq STRING COMMENT  'Store code',
    member_id STRING COMMENT 'Member ID',
    user_id STRING COMMENT 'Operator ID',
    user_name STRING COMMENT 'Operator ID',
    user_tel STRING COMMENT 'Operator phone number',
    head_pic_url STRING COMMENT 'Operator photo',
    member_name STRING COMMENT 'Customer name',
    member_head_pic_url STRING COMMENT 'Customer photo',
    tel STRING COMMENT 'Customer mobile number',
    order_date STRING COMMENT 'Order generation time',
    pay_date STRING COMMENT 'Payment date',
    order_source INT COMMENT 'Order source',
    total_amount INT COMMENT 'Total number',
    total_money INT COMMENT 'Total amount',
    pay_method STRING COMMENT 'Payment method',
    delivery_method STRING COMMENT 'Delivery',
     order_bonuspoint INT COMMENT 'Bonus points'
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

USE dw;

CREATE TABLE IF NOT EXISTS t_member_detail(
    member_id STRING COMMENT 'Member ID',
    member_name STRING COMMENT 'Customer name',
    member_head_pic_url STRING COMMENT 'Customer photo',
    tel STRING COMMENT 'Customer mobile number',
    order_bonuspoint INT COMMENT 'Bonus point',
    uuid STRING COMMENT 'Order ID'
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

CREATE TABLE IF NOT EXISTS t_order_detail(
    uuid STRING COMMENT 'Order ID',
    order_no STRING COMMENT 'Order No',
    org_seq STRING COMMENT 'Store code',
    member_id STRING COMMENT 'Member ID',
    order_date STRING COMMENT 'Order generation time',
    pay_date STRING COMMENT 'Payment date',
    order_source STRING COMMENT 'Order source',
    total_amount INT COMMENT 'Total number',
    total_money INT COMMENT 'Total amount',
    pay_method STRING COMMENT 'Payment method',
    delivery_method STRING COMMENT 'Delivery method'
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

USE ads;

CREATE TABLE IF NOT EXISTS t_member_common(
    member_id STRING COMMENT 'Member ID',
    bonuspoint INT COMMENT 'Total bonus points',
    uuid_num INT COMMENT 'Order ID'
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

CREATE TABLE IF NOT EXISTS t_order_common(
    org_seq STRING COMMENT 'Store code',
    member_num INT COMMENT 'Number of members',
    uuid_num INT COMMENT 'Total number of orders',
    uuid_money INT COMMENT 'Total order amount'
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

LOAD DATA INPATH '/user/data/t_trade_order.csv' INTO TABLE ods.t_trade_order;

INSERT INTO t_order_detail
SELECT
    aux.uuid,
    aux.order_no,
    aux.orq_seq AS org_seq,
    aux.member_id,
    aux.order_date,
    aux.pay_date,
    order_source,
    aux.total_amount,
    aux.total_money,
    CASE
        WHEN aux.pay_method = 0 THEN 'offline payment'
        WHEN aux.pay_method = 1 THEN 'online payment'
        WHEN aux.pay_method = 2 THEN 'WeChat'
        WHEN aux.pay_method = 3 THEN 'Alipay'
        WHEN aux.pay_method = 4 THEN 'bank card'
        ELSE 'unknown'
    END AS pay_method,
    CASE
        WHEN aux.delivery_method = 1 THEN 'walk-in-pickup'
        WHEN aux.delivery_method = 2 THEN 'delivery service'
        WHEN aux.delivery_method = 3 THEN 'express delivery service'
        ELSE 'unknown'
    END AS delivery_method
FROM ods.t_trade_order aux;

INSERT INTO t_member_detail
SELECT
    member_id,
    member_name,
    member_head_pic_url,
    tel,
    order_bonuspoint,
    uuid
FROM ods.t_trade_order aux;

INSERT INTO t_member_common
SELECT
    member_id,
    SUM(aux.order_bonuspoint) AS bonuspoint,
    COUNT(aux.uuid) AS uuid_num
FROM dw.t_member_detail aux
GROUP BY member_id;

SELECT * FROM t_member_common
WHERE member_id = 'member-0503';

INSERT INTO t_order_common
SELECT
    org_seq,
    COUNT(DISTINCT(member_id)) AS member_num,
    COUNT(uuid) AS uuid_num,
    SUM(total_money) AS uuid_money
FROM dw.t_order_detail root
GROUP BY org_seq;

SELECT * FROM t_order_common
WHERE org_seq = '1014';

SELECT member_id, bonuspoint
FROM t_member_common
ORDER BY bonuspoint DESC
LIMIT 10;

SELECT org_seq, uuid_money
FROM t_order_common
ORDER BY uuid_money DESC
LIMIT 10;


sqoop export \
--connect jdbc:mysql://192.168.0.241:3306/ads_common \
--username root \
--password \
--table t_member_common \
--export-dir /user/hive/warehouse/ads.db/t_member_common/000000_0 \
--input-fields-terminated-by ','


sqoop export \
--connect jdbc:mysql://192.168.0.241:3306/ads_common \
--username root \
--password  \
--table t_order_common \
--export-dir /user/hive/warehouse/ads.db/t_order_common/000000_0 \
--input-fields-terminated-by ','
