CREATE DATABASE IF NOT EXISTS stores_data
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE stores_data;

CREATE TABLE stores (
    store_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    address VARCHAR(50) NOT NULL
);

CREATE TABLE sales (
    sale_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    store_id BIGINT UNSIGNED NOT NULL,
    date TIMESTAMP NOT NULL,
    sale_amount DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_sales_store
        FOREIGN KEY (store_id)
        REFERENCES stores (store_id)
);
