SELECT
    food,
    AVG(percent_change) AS avg_growth
FROM (
    SELECT
        food,
        (avg_price - prev_price) / prev_price * 100 AS percent_change
    FROM (
        SELECT
            food,
            year,
            avg_price,
            LAG(avg_price) OVER (PARTITION BY food ORDER BY year) AS prev_price
        FROM (
            SELECT
                food,
                year,
                AVG(avg_price) AS avg_price
            FROM t_michal_solcer_project_SQL_primary_final
            GROUP BY food, year
        ) t1
    ) t2
    WHERE prev_price IS NOT NULL
) t3
GROUP BY food
ORDER BY avg_growth;