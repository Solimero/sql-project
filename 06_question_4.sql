SELECT *
FROM (
    SELECT
        w.year,
        w.wage_growth,
        p.price_growth,
        p.price_growth - w.wage_growth AS diff
    FROM (
        SELECT
            year,
            (avg_wage - prev_wage) / prev_wage * 100 AS wage_growth
        FROM (
            SELECT
                year,
                avg_wage,
                LAG(avg_wage) OVER (ORDER BY year) AS prev_wage
            FROM (
                SELECT
                    year,
                    AVG(avg_wage) AS avg_wage
                FROM t_michal_solcer_project_SQL_primary_final
                GROUP BY year
            ) t1
        ) t2
        WHERE prev_wage IS NOT NULL
    ) w
    JOIN (
        SELECT
            year,
            (avg_price - prev_price) / prev_price * 100 AS price_growth
        FROM (
            SELECT
                year,
                avg_price,
                LAG(avg_price) OVER (ORDER BY year) AS prev_price
            FROM (
                SELECT
                    year,
                    AVG(avg_price) AS avg_price
                FROM t_michal_solcer_project_SQL_primary_final
                GROUP BY year
            ) t1
        ) t2
        WHERE prev_price IS NOT NULL
    ) p
    ON w.year = p.year
) t
WHERE diff > 10;