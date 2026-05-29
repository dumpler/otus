USE stores_data;

WITH monthly_sales AS (
    SELECT
        s.store_id,
        DATE_FORMAT(s.date, '%Y-%m-01') AS month_start,
        SUM(s.sale_amount) AS month_amount
    FROM sales s
    GROUP BY s.store_id, DATE_FORMAT(s.date, '%Y-%m-01')
)
SELECT
    store_id,
    month_start,
    month_amount,
    SUM(month_amount) OVER (
        PARTITION BY store_id
        ORDER BY month_start
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM monthly_sales
ORDER BY store_id, month_start;