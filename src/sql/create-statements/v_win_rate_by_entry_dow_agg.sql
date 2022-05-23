/* Win Rate by entry day of week

*/

-- calculate day of week number
CREATE OR REPLACE VIEW ods.v_win_rate_by_entry_dow_agg AS
WITH 
cte_day_of_week_num AS 
	(
	SELECT 
		v.trade_id
		, v.position_open
		, v.profit_total
		, v.entry_date
		-- Sunday = 0, Saturday = 6
		, EXTRACT(DOW FROM entry_date) AS day_of_week_num
	FROM 
		v_trading_journal AS v
	),
-- calculate trades_won and trades_total for win rate metric
cte_win_rate_data AS
	(
	SELECT
		v.trade_id
		, COUNT(v.trade_id) FILTER (WHERE v.profit_total > 0) OVER(PARTITION BY dow.day_of_week_num) AS trades_won
		, COUNT(v.trade_id) OVER(PARTITION BY dow.day_of_week_num) AS trades_total
		, ROW_NUMBER() OVER(PARTITION BY dow.day_of_week_num ORDER BY v.trade_id) AS row_num_in_window
	FROM
		v_trading_journal AS v
	-- get 'day_of_week_num' from other CTE for this CTE's trades calculations to avoid duplication of day of week calculation
	LEFT JOIN 
		cte_day_of_week_num AS dow
		ON v.trade_id = dow.trade_id
	)
	
-- main query with further calculations and retrieving calculated columns from CTEs by JOIN
SELECT 
	wr.trades_won
	, wr.trades_total
	, ROUND(AVG(wr.trades_won / wr.trades_total::NUMERIC * 100) OVER(PARTITION BY dow.day_of_week_num), 1) AS win_rate_by_entry_day
	, dow.day_of_week_num
	, CASE day_of_week_num
		WHEN 0 THEN 'Sunday'
		WHEN 1 THEN 'Monday'
		WHEN 2 THEN 'Tuesday'
		WHEN 3 THEN 'Wednesday'
		WHEN 4 THEN 'Thursday'
		WHEN 5 THEN 'Friday'
		WHEN 6 THEN 'Saturday'
	END AS day_of_week
FROM
	cte_day_of_week_num AS dow
LEFT JOIN 
	cte_win_rate_data AS wr
	ON dow.trade_id = wr.trade_id
WHERE 
	1 = 1
	-- needed according to 'win rate' metrics definition in README.md (win rate only counts closed trades)
	AND dow.position_open = FALSE
	AND wr.row_num_in_window = 1
ORDER BY 
	dow.day_of_week_num;