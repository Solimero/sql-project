CREATE TABLE t_michal_solcer_project_SQL_primary_final AS
SELECT 
    wage.payroll_year AS year,
    wage.industry,
    wage.avg_wage,
    price.food,
    price.avg_price
FROM (
    SELECT
        cp.payroll_year,
        cpib.name AS industry,
        AVG(cp.value) AS avg_wage
    FROM czechia_payroll cp 
    JOIN czechia_payroll_industry_branch cpib 
        ON cp.industry_branch_code = cpib.code 
    WHERE cp.value_type_code = 5958
      AND cp.calculation_code = 100
    GROUP BY cp.payroll_year, cpib.name
) wage
JOIN (
    SELECT
        EXTRACT(YEAR FROM cp.date_from) AS year,
        cpc.name AS food,
        AVG(cp.value) AS avg_price
    FROM czechia_price cp
    JOIN czechia_price_category cpc
        ON cp.category_code = cpc.code
    GROUP BY EXTRACT(YEAR FROM cp.date_from), cpc.name
) price 
ON wage.payroll_year = price.year;

--kupnísíla

SELECT 	
    year,
    food,
    AVG(avg_wage) / AVG(avg_price) AS amount_can_buy
FROM t_michal_solcer_project_SQL_primary_final
WHERE (food LIKE '%Mléko polotučné%' 
   OR food LIKE '%Chléb konzumní%')
  AND year IN (2006, 2018)
GROUP BY year, food 
ORDER BY food, year;


--nejpomalejší růst
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


--meziroční nárust

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

--vliv DPH

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
        FROM economies
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
) w ON g.year = w.year
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
) p ON g.year = p.year;


CREATE TABLE t_michal_solcer_project_SQL_secondary_final AS
SELECT
    e.country,
    e.year,
    e.GDP,
    e.GINI,
    e.population
FROM economies e
JOIN countries c
    ON e.country = c.country
WHERE c.continent = 'Europe'
  AND e.year BETWEEN 2006 AND 2018;

