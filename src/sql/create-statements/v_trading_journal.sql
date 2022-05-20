-- drop view before reloading db then create view after load
-- DROP VIEW ods.trading_journal_view

CREATE OR REPLACE VIEW ods.trading_journal_view AS WITH cte_cp_cols AS (
	SELECT
		-- METADATA
		trade_id,
		ticker, 
		round(share_amount * entry_price) AS purchase_price_total,
		entry_date ::date AS entry_date,
		ROUND((entry_price::numeric - initial_stop_loss::numeric) / initial_stop_loss::numeric, 3) AS stop_loss_distance,
		-- this is the default date, when nothing was entered
		CASE sell_datetime
		WHEN '1970-01-01 00:00:00' THEN
			TRUE
		ELSE
			FALSE
		END AS position_open,
		
		-- TRADE DETAILS
		share_amount,
		entry_price,
		initial_stop_loss,
		adr_percent,
		ROUND((entry_price::numeric - initial_stop_loss::numeric) / initial_stop_loss::numeric / adr_percent::numeric, 2) AS sl_dist_adr_ratio,
		market_cap,
		CASE WHEN market_cap < 0.3 THEN
			'Micro Cap'
		WHEN market_cap < 2 THEN
			'Small Cap'
		WHEN market_cap < 10 THEN
			'Mid Cap'
		WHEN market_cap < 200 THEN
			'Large Cap'
		WHEN market_cap >= 200 THEN
			'Mega Cap'
		END AS cap_group,
		portfolio_risk,
		
		-- PARTIAL SELL 1
		coalesce(sell_shares_price_1, 0) AS sell_shares_price_1,
		coalesce(sell_shares_amount_1, 0) AS sell_shares_amount_1,
		sell_shares_date_1,
		round(coalesce((sell_shares_price_1 - entry_price) * sell_shares_amount_1, 0)) AS partial_profit_1,
		
		-- PARTIAL SELL 2
		coalesce(sell_shares_price_2, 0) AS sell_shares_price_2,
		coalesce(sell_shares_amount_2, 0) AS sell_shares_amount_2,
		sell_shares_date_2,
		round(coalesce((sell_shares_price_2 - entry_price) * sell_shares_amount_2, 0)) AS partial_profit_2,
		
		-- PARTIAL SELL 3
		coalesce(sell_shares_price_3, 0) AS sell_shares_price_3,
		coalesce(sell_shares_amount_3, 0) AS sell_shares_amount_3,
		sell_shares_date_3,
		round(coalesce((sell_shares_price_3 - entry_price) * sell_shares_amount_3, 0)) AS partial_profit_3,
		
		-- TOTALS
		ROUND((entry_price::numeric - initial_stop_loss::numeric) * share_amount, 0) AS money_at_risk,
		
		-- MISCELLANEOUS
		trello_trade_review,
		setup_rating,
		setup_chart,
		sell_datetime
	FROM
		trading_journal
)
SELECT
	trade_id,
	ticker,
	position_open,
	share_amount,
	purchase_price_total,
	entry_date,
	entry_price,
	initial_stop_loss,
	stop_loss_distance,
	adr_percent,
	sl_dist_adr_ratio,
	market_cap,
	cap_group,
	portfolio_risk,
	sell_shares_price_1,
	sell_shares_amount_1,
	sell_shares_date_1,
	partial_profit_1,
	sell_shares_price_2,
	sell_shares_amount_2,
	sell_shares_date_2,
	partial_profit_2,
	sell_shares_price_3,
	sell_shares_amount_3,
	sell_shares_date_3,
	partial_profit_3,
	money_at_risk,
	-- formula for risk-reward-ratio: profit_total / money_at_risk
	(partial_profit_1::NUMERIC + partial_profit_2::NUMERIC + partial_profit_3::NUMERIC) / money_at_risk::NUMERIC AS risk_reward_ratio,
	partial_profit_1 + partial_profit_2 + partial_profit_3 AS profit_total,
	trello_trade_review,
	setup_rating,
	setup_chart,
	sell_datetime
	
FROM
	cte_cp_cols;

