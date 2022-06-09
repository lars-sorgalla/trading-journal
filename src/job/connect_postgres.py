import csv
from configparser import ConfigParser

from prefect import task
import pyodbc
from pyspark.sql import DataFrame

from src.config import credentials


def connect() -> pyodbc.Connection:
    # read config file
    config_file: str = "/usr/local/etc/odbc.ini"
    config = ConfigParser()
    config.read(config_file)

    # extract values from conf file
    section = config["postgres_trading"]
    driver = section["Driver"]
    server = section["ServerName"]
    port = section["Port"]
    database = section["Database"]
    user = section["Username"]
    password = section["Password"]

    # connect to db
    connection = pyodbc.connect(f"Driver={driver};"
                                 f"Server={server};"
                                 f"Port={port};"
                                 f"Database={database};"
                                 f"Uid={user};"
                                 f"Pwd={password};")
    return connection


@task
def pg_table_to_csv(table: str) -> None:
    """
    Retrieve a table/view from Postgres and load into CSV

    Needed for offline BI tools such as the free Tableau Public, which does not
    support DB connections as a source.

    CSV file is stored in ``[project_root]/data-out/[name_of_table]``

    :param table: name of table or view e.g. 'v_win_rate_cumulative'

    :return: None
    """
    connection = connect()
    cursor = connection.cursor()

    # get table/view from database
    rows = cursor.execute(f"SELECT * FROM ods.{table} ORDER BY 1")

    # write into csv file
    csv_path: str = f"data-out/{table}.csv"
    with open(csv_path, mode="w", newline="") as f:
        writer = csv.writer(f, delimiter=";")
        writer.writerow([elem[0] for elem in cursor.description])
        writer.writerows(rows)


@task
def write_to_postgres(df: DataFrame) -> None:
    pg_user: str = credentials.postgres_login["username"]
    pg_password: str = credentials.postgres_login["password"]

    (df.write
     # driver is needed for subsequent jdbc method
     .option("driver", "org.postgresql.Driver")
     # if "truncate" not set, table would be dropped instead. Attached views
     # hinders this. Solution would be to DROP ... CASCADE, which is not
     # supported using JDBC option in Spark.
     .option("truncate", "true")
     .jdbc(url="jdbc:postgresql://localhost:5432/trading",
           table="ods.trading_journal",
           mode="overwrite",
           properties={"user": pg_user, "password": pg_password}))
