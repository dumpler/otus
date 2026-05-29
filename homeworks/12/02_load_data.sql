SET NAMES utf8mb4;

USE load_data_demo;

TRUNCATE TABLE users;

LOAD DATA
INFILE '/var/lib/mysql-files/users.csv'
INTO TABLE users
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
(email, city);

SELECT
    email,
    city
FROM users
ORDER BY email;
