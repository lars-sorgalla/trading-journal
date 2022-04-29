import pyodbc
from configparser import ConfigParser
from pyspark.sql import DataFrame
from src.config import credentials


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


def get_data() -> None:
    connection = _connect()
    cursor = connection.cursor()
    cursor.execute("select * from staging.trading_journal order by 1")
    for row in cursor.fetchall():
        print(row)


def write_to_postgres(df: DataFrame) -> None:
    pg_user: str = credentials.postgres_login["username"]
    pg_password: str = credentials.postgres_login["password"]

    (df.write
     .option("driver", "org.postgresql.Driver")
     # if "truncate" not set, table would be dropped instead. Attached views hinders this. Solution would be to
     # DROP ... CASCADE, which is not supported using JDBC option in Spark
     .option("truncate", "true")
     .jdbc(url="jdbc:postgresql://localhost:5432/trading", table="ods.trading_journal", mode="overwrite",
           properties={"user": pg_user, "password": pg_password}))


# for debugging
if __name__ == '__main__':
    get_data()