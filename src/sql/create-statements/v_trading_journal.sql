--
-- PostgreSQL database dump
--

-- Dumped from database version 14.1
-- Dumped by pg_dump version 14.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: trading_journal_view; Type: VIEW; Schema: ods; Owner: postgres
--

CREATE VIEW ods.trading_journal_view AS
 SELECT trading_journal.trade_id,
    trading_journal.ticker,
        CASE trading_journal.sell_datetime
            WHEN '1970-01-01 00:00:00'::timestamp without time zone THEN true
            ELSE false
        END AS position_open,
    trading_journal.share_amount,
    round(((trading_journal.share_amount)::double precision * trading_journal.entry_price)) AS purchase_price_total,
    trading_journal.entry_date,
    trading_journal.entry_price,
    trading_journal.initial_stop_loss,
    round((((trading_journal.entry_price)::numeric - (trading_journal.initial_stop_loss)::numeric) / (trading_journal.initial_stop_loss)::numeric), 3) AS stop_loss_distance,
    trading_journal.adr_percent,
    round(((((trading_journal.entry_price)::numeric - (trading_journal.initial_stop_loss)::numeric) / (trading_journal.initial_stop_loss)::numeric) / (trading_journal.adr_percent)::numeric), 2) AS sl_dist_adr_ratio,
    trading_journal.market_cap,
        CASE
            WHEN (trading_journal.market_cap < (0.3)::double precision) THEN 'Micro Cap'::text
            WHEN (trading_journal.market_cap < (2)::double precision) THEN 'Small Cap'::text
            WHEN (trading_journal.market_cap < (10)::double precision) THEN 'Mid Cap'::text
            WHEN (trading_journal.market_cap < (200)::double precision) THEN 'Large Cap'::text
            WHEN (trading_journal.market_cap >= (200)::double precision) THEN 'Mega Cap'::text
            ELSE NULL::text
        END AS cap_group,
    trading_journal.portfolio_risk,
    COALESCE(trading_journal.sell_shares_price_1, (0)::double precision) AS sell_shares_price_1,
    COALESCE(trading_journal.sell_shares_amount_1, (0)::bigint) AS sell_shares_amount_1,
    trading_journal.sell_shares_date_1,
    round(COALESCE(((trading_journal.sell_shares_price_1 - trading_journal.entry_price) * (trading_journal.sell_shares_amount_1)::double precision), (0)::double precision)) AS partial_profit_1,
    COALESCE(trading_journal.sell_shares_price_2, (0)::double precision) AS sell_shares_price_2,
    COALESCE(trading_journal.sell_shares_amount_2, (0)::bigint) AS sell_shares_amount_2,
    trading_journal.sell_shares_date_2,
    round(COALESCE(((trading_journal.sell_shares_price_2 - trading_journal.entry_price) * (trading_journal.sell_shares_amount_2)::double precision), (0)::double precision)) AS partial_profit_2,
    COALESCE(trading_journal.sell_shares_price_3, (0)::double precision) AS sell_shares_price_3,
    COALESCE(trading_journal.sell_shares_amount_3, (0)::bigint) AS sell_shares_amount_3,
    trading_journal.sell_shares_date_3,
    round(COALESCE(((trading_journal.sell_shares_price_3 - trading_journal.entry_price) * (trading_journal.sell_shares_amount_3)::double precision), (0)::double precision)) AS partial_profit_3,
    round((((trading_journal.entry_price)::numeric - (trading_journal.initial_stop_loss)::numeric) * (trading_journal.share_amount)::numeric), 0) AS money_at_risk,
    round((((round((COALESCE(((trading_journal.sell_shares_price_1)::numeric - (trading_journal.entry_price)::numeric), (0)::numeric) * COALESCE((trading_journal.sell_shares_amount_1)::numeric, (0)::numeric))) + round((COALESCE(((trading_journal.sell_shares_price_2)::numeric - (trading_journal.entry_price)::numeric), (0)::numeric) * COALESCE((trading_journal.sell_shares_amount_2)::numeric, (0)::numeric)))) + round((COALESCE(((trading_journal.sell_shares_price_3)::numeric - (trading_journal.entry_price)::numeric), (0)::numeric) * COALESCE((trading_journal.sell_shares_amount_3)::numeric, (0)::numeric)))) / round((((trading_journal.entry_price)::numeric - (trading_journal.initial_stop_loss)::numeric) * (trading_journal.share_amount)::numeric), 0)), 2) AS risk_reward_ratio,
    ((round((COALESCE((trading_journal.sell_shares_price_1 - trading_journal.entry_price), (0)::double precision) * (COALESCE(trading_journal.sell_shares_amount_1, (0)::bigint))::double precision)) + round((COALESCE((trading_journal.sell_shares_price_2 - trading_journal.entry_price), (0)::double precision) * (COALESCE(trading_journal.sell_shares_amount_2, (0)::bigint))::double precision))) + round((COALESCE((trading_journal.sell_shares_price_3 - trading_journal.entry_price), (0)::double precision) * (COALESCE(trading_journal.sell_shares_amount_3, (0)::bigint))::double precision))) AS profit_total,
    trading_journal.trello_trade_review,
    trading_journal.setup_rating,
    trading_journal.setup_chart,
    trading_journal.sell_datetime
   FROM ods.trading_journal;


ALTER TABLE ods.trading_journal_view OWNER TO postgres;

--
-- PostgreSQL database dump complete
--

