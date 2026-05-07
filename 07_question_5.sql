SELECT
    g.year,
    g.gdp_growth,
    w.wage_growth,
    p.price_growth
FROM (
    SELECT
        year,
        (GDP - prev_GDP) / prev_GDP * 100 AS gdp_growth
    FROM (
        SELECT
            year,
            GDP,
            LAG(GDP) OVER (ORDER BY year) AS prev_GDP
        FROM t_michal_solcer_project_SQL_secondary_final
        WHERE country = 'Czech Republic'
    ) t1
    WHERE prev_GDP IS NOT NULL
) g
JOIN (
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
        ) t2
    ) t3
    WHERE prev_wage IS NOT NULL
) w
ON g.year = w.year
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
        ) t4
    ) t5
    WHERE prev_price IS NOT NULL
) p
ON g.year = p.year;