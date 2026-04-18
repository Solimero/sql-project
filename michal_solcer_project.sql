select 
	cp.payroll_year,
	cpib.name as industry,
	AVG(cp.value) as  avg_wage
from czechia_payroll cp
join czechia_payroll_industry_branch cpib 
	on cp.industry_branch_code = cpib.code 
where cp.value_type_code = 5958
and cp.calculation_code = 100
group by cp.payroll_year, cpib."name" 
order by cp.payroll_year;


select 
	extract(year from cp.date_from) as year,
	cpc.name as food,
	AVG(cp.value) as avg_price
from czechia_price cp
join czechia_price_category cpc 
	on cp.category_code = cpc.code 
group by extract(year from cp.date_from), cpc.name
order by year;


create table t_michal_solcer_project_SQL_primary_final AS
select 
	wage.payroll_year as year,
	wage.industry,
	wage.avg_wage,
	price.food,
	price.avg_price
from (
	--mzdy
	select
		cp.payroll_year,
		cpib.name as industry,
		AVG(cp.value) as avg_wage
	from czechia_payroll cp 
	join czechia_payroll_industry_branch cpib 
		on cp.industry_branch_code = cpib.code 
	where cp.value_type_code = 5958
	and cp.calculation_code = 100
	group by cp.payroll_year, cpib.name
) wage
join (
	--ceny
	select
		extract(year from cp.date_from) as year,
		cpc.name as food,
		AVG(cp.value) as avg_price
	from czechia_price cp
	join czechia_price_category cpc
		on cp.category_code = cpc.code
	group by extract(year from cp.date_from), cpc.name
) price 
on wage.payroll_year = price.year;

--výsdledek

select*
from t_michal_solcer_project_SQL_primary_final
limit 10;


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
) t2;

-- to se asi opakuje, ale hledám něco jiného

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

--zjištění roku
select 
	min(year) as first_year,
	max(year) as last_year
from t_michal_solcer_project_sql_primary_final;

select 	
	year,
	food,
	avg(avg_wage) / AVG(avg_price) as amount_can_buy
from t_michal_solcer_project_sql_primary_final
where (food like '%Mléko polotučné pasterované%' or food like '%Chléb konzumní kmínový%')
	and year in (2006, 2018)
group by year, food 
order by food, year;

--zjištění správného názvu potravin
--pro upravu horních řádků

select distinct food
from t_michal_solcer_project_sql_primary_final
order by food;

--Když porovnám roky 2006 a 2018, tak je vidět, že si lidé za průměrnou mzdu mohli koupit víc chleba i mléka. 
--Konkrétně u chleba to bylo zhruba z 1 261 kg na 1 319 kg a u mléka z 1 409 litrů na 1 614 litrů.
--Zjednodušeně řečeno, kupní síla se v průběhu let zlepšila.

--pomalé zdraažování potraviny

select 
	food,
	year,
	avg_price,
	LAG(avg_price) over (partition by food order by year) as prev_price
from (
	select 
		food,
		year,
		avg(avg_price) as avg_price
	FROM t_michal_solcer_project_SQL_primary_final
	group by food, year
) t;


--zjistíme jestli to rostlo

SELECT
    food,
    year,
    avg_price,
    prev_price,
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
) t2;

-- ted u čeho rostla cena pomaleji

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


-- vypadá to že cukr spíše dokonce ještě zlevnil. 
-- To znamená že cukr v průběhu let spíše zlevnoval než zdražoval,

-- Další část Existuje rok, kdy ceny rostly výrazně víc než mzdy (o více než 10 %)?

-- růst mezd?

select 
	year,
	avg_wage, 
	LAG(avg_wage) over (order by year) as prev_wage
from (
	select
		year,
		AVG(avg_wage) as avg_wage
	from t_michal_solcer_project_SQL_primary_final
	group by year
) t;

-- procentualní růst mezd

select 
	year,
	(avg_wage - prev_wage) / prev_wage * 100 as wage_growth
from (
	select
		year,
		avg_wage,
		LAG(avg_wage) over (order by year) as prev_wage
	from (
		select
			year,
			avg(avg_wage) as avg_wage
		from t_michal_solcer_project_sql_primary_final 
		group by year
	) t1
) t2
where prev_wage is not null;

-- stoupající mzdy

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
WHERE prev_price IS NOT NULL;

-- rozdíl v avg_price místo avg_wage

-- další krok

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
ON w.year = p.year;


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


--Z dat nevyplývá, že by existoval rok, kdy by ceny potravin rostly o více než 10 % rychleji než mzdy.
--I když ceny někdy rostly víc než mzdy, rozdíl nikdy nebyl tak velký.

--Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
--projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

select
	year,
	(GDP - prev_GDP) / prev_GDP * 100 as gdp_growth
from (
	select
		year, 
		GDP,
		lag(GDP) over (order by year) as prev_GDP
	from economies
	where country = 'Czech Republic'
) t
where prev_GDP is not null;

-- samostatný soupis gdp_growth

--ted dáme vče dohromady pro zjištění HDP


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


-- Z porovnání vývoje HDP, mezd a cen potravin je vidět, že mezi nimi neexistuje jednoznačná přímá závislost.
--V některých letech růst HDP doprovázel i růst mezd a cen, ale v jiných obdobích tento vztah nebyl tak zřejmý. 
--Například v některých letech HDP rostlo, ale mzdy nebo ceny nerostly stejným tempem.
--Výsledkem je, že HDP může mít vliv na ekonomiku jako celek, ale nelze říct, že by jeho změny vždy přímo určovaly vývoj mezd a cen potravin.


-- doladěni podle požadavku 

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
























