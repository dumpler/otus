USE product_testing;

SELECT
    product_id,
    title,
    category_id,
    price,
    rating,
    status
FROM products
ORDER BY status_sort, price
LIMIT 50;

SET @last_status_sort = 0;
SET @last_price = 62;

SELECT
    product_id,
    title,
    category_id,
    price,
    rating,
    status
FROM products
WHERE (status_sort, price) > (@last_status_sort, @last_price)
ORDER BY status_sort, price
LIMIT 50;

EXPLAIN
SELECT
    product_id,
    title,
    category_id,
    price,
    rating,
    status
FROM products
WHERE (status_sort, price) > (@last_status_sort, @last_price)
ORDER BY status_sort, price
LIMIT 50;
