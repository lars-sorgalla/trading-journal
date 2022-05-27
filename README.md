# Introduction

This application is a trading analysis tool. It loads trade data from Google
Sheets and transforms it using Apache Spark. Finally, the cleansed data is
loaded into a Postgresql database for multi-purpose consumption as well as into
CSV for Tableau visualization.

The main programming language is Python.

# 1. Basic Architecture

The entry point to this program is the `main()` function in `etl_job.py`.

# 2. Installing And Executing The Program
It is recommended to start the application from the command line. Therefore,
`cd` into the main module directory and execute the application

```zsh
cd /src/job/
python3 etl_job.py
```

# 3. Metrics Definitions
- win rate
  - Description / Usage: A ratio to measure trading success
  - Calculation: `trades won / trades total`
  - `trades won` = every closed trade whose profit > 0 (when = 0, it's
  considered a losing trade)
  - `trades total` = amount of all closed trades since inception of the
  trading account

# 4. Things I Learned
## 4.1. Be careful with `git clean -f`
The Python interpreter created `__pycache__` directories, that I wanted to get
rid of. So I executed this git command. What I did not consider is the fact,
that it also removed any files listed in `.gitignore`. This is because the
command removes _all_ untracked files. Thus also files for my credentials,
api keys etc were removed. These were part of `.gitignore`.

So instead I will from now on always add the `--interactive OR -i` option, to
go through each file and decide whether I want to keep or discard it.

## 4.2. Tool selection - popularity > "hotness"
I selected Prefect as my workflow orchestration tool. The default tool for this
purpose often is Apache Airflow. It was a conscious decision to take Prefect
instead, as I read that it has useful features which Airflow does not have such
as dynamic task generation (actually outdated, as the newest release supports
this IIRC), data dependencies (as opposed to mere task dependencies) etc.

Well, it turned out, that finding support online is much harder with Prefect
than with Airflow. Less StackOverflow questions, little Medium articles and
so on.

For now I will stick with prefect, as it's already integrated. But I will
consider changing to Airflow.

## 4.3. SQL - CTEs enable DRY principles and improve clarity
Just recently I started to improve my SQL skills to go beyond the very basics
of projection (`SELECT`), selection (`WHERE`), aggregation (`GROUP BY`) etc.
I heard a lot about CTEs that they would improve readability and avoid code
duplication.

These 2 factors (hard to read + duplicate code) was something, that really
annoyed me as a SQL beginner. Coming from several months of knowledge in
Python, it felt weird and unintuitive.

Consider this example for a query against a product price table of an
e-commerce shop:
```SQL
SELECT
  unit_price * (1 + value_added_tax) AS gross_price
FROM
  product_price
WHERE
  unit_price * (1 + value_added_tax) > 0
```

Why do I need to repeat the calculation under `SELECT` again under `WHERE`?! I
know the reasoning behind it. It has to do with the execution order: `WHERE`
comes before `SELECT` in the query plan. So it becomes unreadable and leads to
code duplication.

With CTEs this is not an issue anymore. So I constantly use CTEs now. For me
it's similar to a python function as it allows referencing the code somewhere
else in the query.
