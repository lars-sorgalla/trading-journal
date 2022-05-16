-- drop view before reloading db then create view after load
-- DROP VIEW ods.trading_journal_view

CREATE OR REPLACE VIEW ods.trading_journal_view
 AS
 SELECT 

-- METADATA
 	trading_journal.trade_id,
	trading_journal.ticker,
	-- this is the default date, when nothing was entered
	CASE trading_journal.sell_datetime
		WHEN '1970-01-01 00:00:00' THEN true
		ELSE false
	END AS position_open,

-- TRADE DETAILS
	trading_journal.share_amount,
	round(trading_journal.share_amount * trading_journal.entry_price) AS purchase_price_total,
	trading_journal.entry_date::date AS entry_date,
	trading_journal.entry_price,
	trading_journal.initial_stop_loss,
	ROUND((trading_journal.entry_price::numeric - trading_journal.initial_stop_loss::numeric) / trading_journal.initial_stop_loss::numeric,3) AS stop_loss_distance,
	trading_journal.adr_percent,
	ROUND((trading_journal.entry_price::numeric - trading_journal.initial_stop_loss::numeric) / trading_journal.initial_stop_loss::numeric / trading_journal.adr_percent::numeric, 2) as sl_dist_adr_ratio,
	trading_journal.market_cap,
	CASE
		WHEN trading_journal.market_cap<0.3 THEN 'Micro Cap'
		WHEN trading_journal.market_cap<2 THEN 'Small Cap'
		WHEN trading_journal.market_cap<10 THEN 'Mid Cap'
		WHEN trading_journal.market_cap<200 THEN 'Large Cap'
		WHEN trading_journal.market_cap>=200 THEN 'Mega Cap'
	END AS cap_group,
	trading_journal.portfolio_risk,

-- PARTIAL SELL 1
	coalesce(trading_journal.sell_shares_price_1, 0) as sell_shares_price_1,
	coalesce(trading_journal.sell_shares_amount_1, 0) as sell_shares_amount_1,
	trading_journal.sell_shares_date_1,
	round(coalesce((trading_journal.sell_shares_price_1 - trading_journal.entry_price) * trading_journal.sell_shares_amount_1, 0)) AS partial_profit_1,

-- PARTIAL SELL 2
	coalesce(trading_journal.sell_shares_price_2, 0) as sell_shares_price_2,
	coalesce(trading_journal.sell_shares_amount_2, 0) as sell_shares_amount_2,
	trading_journal.sell_shares_date_2,
	round(coalesce((trading_journal.sell_shares_price_2 - trading_journal.entry_price) * trading_journal.sell_shares_amount_2, 0)) AS partial_profit_2,

-- PARTIAL SELL 3
	coalesce(trading_journal.sell_shares_price_3, 0) as sell_shares_price_3,
	coalesce(trading_journal.sell_shares_amount_3, 0) as sell_shares_amount_3,
	trading_journal.sell_shares_date_3,
	round(coalesce((trading_journal.sell_shares_price_3 - trading_journal.entry_price) * trading_journal.sell_shares_amount_3, 0)) AS partial_profit_3,

-- TOTALS
	ROUND((trading_journal.entry_price::numeric - trading_journal.initial_stop_loss::numeric) * trading_journal.share_amount, 0) 
	AS money_at_risk,
	
	-- formula: profit_total / money_at_risk
	round(
		(round(coalesce(trading_journal.sell_shares_price_1::numeric - trading_journal.entry_price::numeric, 0) * coalesce(trading_journal.sell_shares_amount_1::numeric, 0)) 
		+ round(coalesce(trading_journal.sell_shares_price_2::numeric - trading_journal.entry_price::numeric, 0) * coalesce(trading_journal.sell_shares_amount_2::numeric, 0)) 
		+ round(coalesce(trading_journal.sell_shares_price_3::numeric - trading_journal.entry_price::numeric, 0) * coalesce(trading_journal.sell_shares_amount_3::numeric, 0))) 
		/ (ROUND((trading_journal.entry_price::numeric - trading_journal.initial_stop_loss::numeric) * trading_journal.share_amount, 0)), 2) 
	as risk_reward_ratio,
	
	round(coalesce(trading_journal.sell_shares_price_1 - trading_journal.entry_price, 0) * coalesce(trading_journal.sell_shares_amount_1, 0)) 
	+ round(coalesce(trading_journal.sell_shares_price_2 - trading_journal.entry_price, 0) * coalesce(trading_journal.sell_shares_amount_2, 0)) 
	+ round(coalesce(trading_journal.sell_shares_price_3 - trading_journal.entry_price, 0) * coalesce(trading_journal.sell_shares_amount_3, 0)) 
	AS profit_total,
	
-- MISCELLANEOUS
	trading_journal.trello_trade_review,
	trading_journal.setup_rating,
	trading_journal.setup_chart,
	trading_journal.sell_datetime
	
 FROM ods.trading_journal;

