CREATE DATABASE IF NOT EXISTS product_testing
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE product_testing;

CREATE TABLE IF NOT EXISTS categories (
    category_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(32) NOT NULL,
    PRIMARY KEY (category_id),
    UNIQUE KEY uq_categories_title (title)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS products (
    product_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(64) NOT NULL,
    category_id BIGINT UNSIGNED NOT NULL,
    price INT UNSIGNED NOT NULL,
    rating TINYINT UNSIGNED NOT NULL,
    status ENUM('В наличии', 'Распродан') NOT NULL,
    status_sort TINYINT UNSIGNED
        GENERATED ALWAYS AS (
            CASE status
                WHEN 'В наличии' THEN 0
                ELSE 1
            END
        ) STORED,
    PRIMARY KEY (product_id),
    UNIQUE KEY uq_products_price (price),
    KEY idx_products_category (category_id),
    KEY idx_products_page (status_sort, price),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES categories (category_id),
    CONSTRAINT chk_products_price_positive
        CHECK (price > 0),
    CONSTRAINT chk_products_rating_range
        CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;

DROP PROCEDURE IF EXISTS generate_test_products;
DROP TRIGGER IF EXISTS trg_products_validate_insert;
DROP TRIGGER IF EXISTS trg_products_validate_update;

DELIMITER //

CREATE TRIGGER trg_products_validate_insert
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    IF NEW.price = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Product price must be greater than zero';
    END IF;

    IF NEW.rating < 1 OR NEW.rating > 5 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Product rating must be between 1 and 5';
    END IF;
END//

CREATE TRIGGER trg_products_validate_update
BEFORE UPDATE ON products
FOR EACH ROW
BEGIN
    IF NEW.price = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Product price must be greater than zero';
    END IF;

    IF NEW.rating < 1 OR NEW.rating > 5 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Product rating must be between 1 and 5';
    END IF;
END//

CREATE PROCEDURE generate_test_products()
BEGIN
    DECLARE category_number INT DEFAULT 1;
    DECLARE current_category_id BIGINT UNSIGNED;

    CREATE TEMPORARY TABLE IF NOT EXISTS seq_10000 (
        n INT UNSIGNED NOT NULL PRIMARY KEY
    ) ENGINE=MEMORY;

    INSERT IGNORE INTO seq_10000 (n)
    SELECT
        ones.n + tens.n * 10 + hundreds.n * 100 + thousands.n * 1000 + 1 AS n
    FROM (
        SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    ) ones
    CROSS JOIN (
        SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    ) tens
    CROSS JOIN (
        SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    ) hundreds
    CROSS JOIN (
        SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    ) thousands
    WHERE ones.n + tens.n * 10 + hundreds.n * 100 + thousands.n * 1000 + 1 <= 10000;

    WHILE category_number <= 20 DO
        INSERT INTO categories (title)
        VALUES (CONCAT('Category ', LPAD(category_number, 2, '0')));

        SET current_category_id = LAST_INSERT_ID();

        INSERT INTO products (
            title,
            category_id,
            price,
            rating,
            status
        )
        SELECT
            CONCAT('Product ', LPAD(category_number, 2, '0'), '-', LPAD(n, 5, '0')),
            current_category_id,
            (category_number - 1) * 10000 + n,
            1 + (n % 5),
            IF(n % 5 = 0, 'Распродан', 'В наличии')
        FROM seq_10000
        ORDER BY n;

        SET category_number = category_number + 1;
    END WHILE;
END//

DELIMITER ;
