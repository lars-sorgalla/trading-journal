import pyodbc
from configparser import ConfigParser
from pyspark.sql import DataFrame
from src.config import credentials
import csv


def _connect() -> pyodbc.Connection:
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
    connection = pyodbc.connect(
        f"Driver={driver};Server={server};Port={port};Database={database};Uid={user};Pwd={password};")
    return connection


def load_pg_view_to_csv() -> None:
    connection = _connect()
    cursor = connection.cursor()
    rows = cursor.execute("select * from ods.trading_journal_view order by 1")
    with open("data-out/trading_journal_view.csv", mode="w", newline="") as f:
        writer = csv.writer(f, delimiter=";")
        writer.writerow([elem[0] for elem in cursor.description])
        writer.writerows(rows)


def write_to_postgres(df: DataFrame) -> None:
    pg_user: str = credentials.postgres_login["username"]
    pg_password: str = credentials.postgres_login["password"]

    (df.write
     # driver is needed for subsequent jdbc method
     .option("driver", "org.postgresql.Driver")
     # if "truncate" not set, table would be dropped instead. Attached views hinders this. Solution would be to
     # DROP ... CASCADE, which is not supported using JDBC option in Spark
     .option("truncate", "true")
     .jdbc(url="jdbc:postgresql://localhost:5432/trading", table="ods.trading_journal", mode="overwrite",
           properties={"user": pg_user, "password": pg_password}))


# for debugging
if __name__ == '__main__':
    load_pg_view_to_csv()
