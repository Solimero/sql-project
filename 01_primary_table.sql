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

