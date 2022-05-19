/* SMA10 For Win Rate 

CTE calculates winning and total trades. These attributes are referenced in the subsequent SELECT query to calculate the 10 day moving average of the win rate
*/
WITH cte_trades_won_and_totals AS
	(
	SELECT
		trade_id
		, sell_shares_date_3
		, sell_datetime
		, COUNT(trade_id) FILTER (WHERE profit_total > 0) OVER(ORDER BY sell_shares_date_3) AS trades_won
		, COUNT(trade_id) OVER(ORDER BY sell_shares_date_3) AS trades_total
		, ROW_NUMBER() OVER(PARTITION BY sell_shares_date_3 ORDER BY sell_datetime DESC) AS row_num_in_window
	FROM 
		trading_journal_view
	WHERE 
		1 = 1
		AND position_open = FALSE
	)
SELECT 
	trade_id
	, sell_shares_date_3
	, sell_datetime
	, trades_won
	, trades_total
	, ROUND(AVG(trades_won / trades_total::NUMERIC * 100) OVER(ORDER BY sell_shares_date_3 ROWS BETWEEN 9 PRECEDING 	AND CURRENT ROW), 1) AS win_rate_10_sma
	, ROUND(AVG(trades_won / trades_total::NUMERIC * 100) OVER(PARTITION BY sell_shares_date_3), 1) AS win_rate_cumulative
	, row_num_in_window
FROM cte_trades_won_and_totals AS t
WHERE row_num_in_window = 1 --filter for latest closed trade of the day to have only one row per day
ORDER BY sell_datetime;