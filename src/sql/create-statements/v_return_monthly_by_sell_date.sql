
/* Monthly Total Return 

Get the absolute monthly return in $.
*/

-- all base columns from main view
CREATE OR REPLACE VIEW v_return_monthly_by_sell_date AS 
WITH cte_base_columns AS 
    (
    SELECT
        trade_id
        , profit_total
        , sell_datetime
        , position_open
    FROM
        v_trading_journal
    ),
    
-- calculate month from sell_datetime column
cte_month_from_date AS 
    (
    SELECT
        trade_id
        , TO_CHAR(sell_datetime, 'YYYY-MM') AS month_of_date
    FROM
        cte_base_columns
    ),

-- separate CTE to generate row number to avoid code duplication in final query in WHERE clause
cte_get_row_num AS
	(
	SELECT
		trade_id
		, ROW_NUMBER() OVER(PARTITION BY month_of_date) as row_num
	FROM
		-- this CTE references the upper CTE as it needs its calculated column 'month_of_date'
		cte_month_from_date
	),
	
-- get sum for profit per month
cte_profit_per_month AS
	(
	SELECT
		b.trade_id
		, SUM(b.profit_total) OVER(PARTITION BY d.month_of_date) AS sum_profit_per_month
	FROM
		cte_month_from_date AS d
	-- get profit total column from base CTE to calculate sum profit per month
	LEFT JOIN
		cte_base_columns AS b
		ON d.trade_id = b.trade_id
	)
    
-- main query
-- each CTE is joined with the base CTE on the trade_id which is contained in every CTE to enable 
-- these joins. 
-- Here the WHERE clause is applied in a separate final query as otherwise it would affect the sum
SELECT
    d.month_of_date
    , sum_profit_per_month
FROM
    cte_base_columns AS b
LEFT JOIN
    cte_month_from_date AS d
    ON b.trade_id = d.trade_id
LEFT JOIN
	cte_get_row_num AS r
	ON b.trade_id = r.trade_id
LEFT JOIN
	cte_profit_per_month AS p
	ON b.trade_id = p.trade_id
WHERE
    b.position_open = FALSE
    AND r.row_num = 1
ORDER BY
	d.month_of_date;
