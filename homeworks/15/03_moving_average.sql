USE stores_data;

WITH top_store AS (
    SELECT store_id
    FROM sales
    GROUP BY store_id
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
daily_sales AS (
    SELECT
        DATE(s.date) AS sale_date,
        SUM(s.sale_amount) AS day_amount
    FROM sales s
    JOIN top_store ts ON ts.store_id = s.store_id
    WHERE s.date >= CURDATE() - INTERVAL 1 MONTH
    GROUP BY DATE(s.date)
)
SELECT
    sale_date,
    day_amount,
    AVG(day_amount) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7_days
FROM daily_sales
ORDER BY sale_date;