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

  