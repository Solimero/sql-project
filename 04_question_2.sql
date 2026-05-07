SELECT 	
    year,
    food,
    AVG(avg_wage) / AVG(avg_price) AS amount_can_buy
FROM t_michal_solcer_project_SQL_primary_final
WHERE (
        food LIKE '%Mléko polotučné pasterované%'
        OR food LIKE '%Chléb konzumní kmínový%'
      )
  AND year IN (2006, 2018)
GROUP BY year, food 
ORDER BY food, year;