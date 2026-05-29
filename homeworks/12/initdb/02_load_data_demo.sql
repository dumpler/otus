CREATE DATABASE IF NOT EXISTS load_data_demo
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE load_data_demo;

CREATE TABLE IF NOT EXISTS users (
    email VARCHAR(255) NOT NULL,
    city VARCHAR(64),
    PRIMARY KEY (email)
) ENGINE=InnoDB;
