USE product_testing;

CALL generate_test_products();

SELECT
    count(*) AS categories_count
FROM categories;

SELECT
    count(*) AS products_count,
    count(DISTINCT price) AS unique_prices_count,
    min(price) AS min_price,
    max(price) AS max_price
FROM products;
