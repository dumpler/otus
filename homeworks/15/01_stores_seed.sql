SET SESSION cte_max_recursion_depth = 100000;
USE stores_data;

DROP PROCEDURE IF EXISTS seed_data;

DELIMITER //

CREATE PROCEDURE seed_data()
BEGIN
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE sales;
    TRUNCATE TABLE stores;
    SET FOREIGN_KEY_CHECKS = 1;

    -- 10 магазинов
    INSERT INTO stores(address)
    WITH RECURSIVE store_seq AS (
        SELECT 1 AS n
        UNION ALL
        SELECT n + 1
        FROM store_seq
        WHERE n < 10
    )
    SELECT CONCAT('Store address ', n)
    FROM store_seq;

    -- 100000 продаж
    INSERT INTO sales(store_id, date, sale_amount)
    WITH RECURSIVE sale_seq AS (
        SELECT 1 AS n
        UNION ALL
        SELECT n + 1
        FROM sale_seq
        WHERE n < 100000
    )
    SELECT
        CASE
            WHEN RAND() < 0.73 THEN 1
            ELSE FLOOR(2 + RAND() * 9)
        END AS store_id,
        NOW()
            - INTERVAL FLOOR(RAND() * 730) DAY
            - INTERVAL FLOOR(RAND() * 86400) SECOND AS date,
        ROUND(10 + RAND() * 990, 2) AS sale_amount
    FROM sale_seq;
END //

DELIMITER ;

CALL seed_data();
