SELECT *
FROM (
    SELECT
        industry,
        year,
        avg_wage,
        prev_wage,
        avg_wage - prev_wage AS diff
    FROM (
        SELECT
            industry,
            year,
            avg_wage,
            LAG(avg_wage) OVER (PARTITION BY industry ORDER BY year) AS prev_wage
        FROM (
            SELECT
                industry,
                year,
                AVG(avg_wage) AS avg_wage
            FROM t_michal_solcer_project_SQL_primary_final
            GROUP BY industry, year
        ) t1
    ) t2
) t3
WHERE diff < 0;