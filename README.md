# Introduction

This application is a trading analysis tool. It loads trade data from Google Sheets and transforms it using Apache
Spark. Finally, the cleansed data is loaded into a Postgresql database for multi-purpose consumption as well as into CSV
for Tableau visualization. 

The main programming language is Python.

# 1. Basic Architecture

The entry point to this program is the `main()` function in `etl_job.py`.

# 2. Installing And Executing The Program
It is recommended to start the application from the command line. Therefore, `cd` into the main module directory and
execute the application

```zsh
cd /src/job/
python3 etl_job.py
```

# 3. Metrics Definitions
- win rate
  - Description / Usage: A ratio to measure trading success
  - Calculation: `trades won / trades total`
  - `trades won` = every closed trade whose profit > 0 (when = 0, it's considered a losing trade)
  - `trades total` = amount of all closed trades since inception of the trading account
