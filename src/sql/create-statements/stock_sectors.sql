CREATE TABLE IF NOT EXISTS stock_sectors (
    stock_id SERIAL PRIMARY KEY
    , ticker TEXT UNIQUE
    , sector TEXT NOT NULL
    , industry TEXT NOT NULL
);