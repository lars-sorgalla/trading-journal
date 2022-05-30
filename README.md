# Introduction

This application is a trading analysis tool. It loads trade data from Google
Sheets and transforms it using Apache Spark. Finally, the cleansed data is
loaded into a Postgresql database for multi-purpose consumption as well as into
CSV for Tableau visualization.

The main programming language is Python.

# 1. Basic Architecture

The entry point to this program is the `main()` function in `etl_job.py`.

# 2. Installing And Executing The Program
## 2.1. Execute Main Script
It is recommended to start the application from the command line. Therefore,
`cd` into the root project directory and execute the application using the
-m option of the python command-line program. The file is provided as a module
in dot notation.

```zsh
# executed in activated virtual environment
cd /src/job/
python -m src.job.etl_job
```

This actually gave me some headaches. I had the special case, that the main
script for this project is not placed in the top-level directory. So I needed
this special syntax. For details see the section on
[Script Execution](#44-script-execution---my-special-case)

## 2.2. Update Architecture Diagram
There is a package installed called `diagrams` which graphically shows the
architecture. The diagram can be manually updated by calling

```zsh
# executed in activated virtual environment
cd trading_journal  # this is the projects' top-level directory
python diagrams.py

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

## 4.4. Script Execution - My Special Case

The main script for this project is not located in its top-level directory.
When I wanted to execute it the normal way, I received several `ModuleNotFound`
errors. This did not work:

```zsh
# executed in activated virtual environment
cd trading_journal/src/job/  # go into main script dir
python etl_job.py
```

After some investigation and googling I found out that in such cases it is
necessary to call the main script as a module, instead of as a script. This
worked:

```zsh
# executed in activated virtual environment
cd trading_journal  # go into top-level project directory
python -m src.job.etl_job
```

I am not sure about the exact details of why this works. But it has to do with
the **Python Module Search Path**. The directory that contains the called
script is added to the PYTHONPATH. This environment variable enables the
interpreter to find modules. The first `python` call shown above would add
`trading_journal/src/job/` to the search path. In that case the interpreter
could not find any packages or modules that are in another project sub-directory
than `src/job/`.
