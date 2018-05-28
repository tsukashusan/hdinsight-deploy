DROP TABLE IF EXISTS warning;

CREATE EXTERNAL TABLE warning(votingday STRING,
  municipality STRING,
  point STRING,
  latitude DOUBLE,
  longitude DOUBLE,
  count INT,
  runnynose INT,
  cough INT,
  throat INT,
  fever INT,
  `0-6count` INT,
  `0-6runnynose` INT,
  `0-6cough` INT,
  `0-6throat` INT,
  `0-6fever` INT,
  `7-12count` INT,
  `7-12runnynose` INT,
  `7-12cough` INT,
  `7-12throat` INT,
  `7-12fever` INT,
  `13-18count` INT,
  `13-18runnynose` INT,
  `13-18cough` INT,
  `13-18throat` INT,
  `13-18fever` INT,
  `19-64count` INT,
  `19-64runnynose` INT,
  `19-64cough` INT,
  `19-64throat` INT,
  `19-64fever` INT,
  `over65count` INT,
  `over65runnynose` INT,
  `over65cough` INT,
  `over65throat` INT,
  `over65ferver` INT ) 
ROW FORMAT SERDE "org.apache.hadoop.hive.serde2.OpenCSVSerde" 
WITH SERDEPROPERTIES (
  "separatorChar"=",", "quoteChar"="\u0022"
)
LOCATION "<locationPath>" tblproperties ("skip.header.line.count" = "1");
