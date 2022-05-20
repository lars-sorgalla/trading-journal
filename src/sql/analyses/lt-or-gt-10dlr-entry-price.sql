select
	case
		when entry_price < 10 then 'less than 10$'
		when entry_price >= 10 then 'greater than 10$'
	end as stock_price_group,
	count(*) as count_trades,
	sum(profit_total) as sum_profits_in_dollar,
	round(avg(risk_reward_ratio), 2) as avg_risk_reward_ratio
from ods.v_trading_journal
group by stock_price_group;


