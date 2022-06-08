CREATE TABLE IF NOT EXISTS stock_sectors (
    stock_id SERIAL PRIMARY KEY
    , ticker TEXT UNIQUE NOT NULL
    , sector TEXT NOT NULL
    , industry TEXT NOT NULL
);

DROP TABLE stock_sectors