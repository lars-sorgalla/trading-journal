from datetime import datetime, timedelta

import prefect.engine.state as st
import pyspark.sql.functions as F
from prefect import task, Flow
from pyspark.sql import SparkSession, DataFrame
from pyspark.sql.types import (
    StructType,
    StructField,
    StringType,
    DecimalType,
    IntegerType,
    TimestampType)

import src.config.schema as s
import src.job.connect_postgres as cpg
import src.job.extract_gsheets as gs

APP_NAME = "gsheets-trading-journal-to-postgres"
EPOCH = "1899-12-30"  # epoch start date in Google Sheets


def start_spark(app_name: str) -> SparkSession:
    """Entry point to Spark by creating SparkSession with config parameters

    To make SparkUI persistent, the config 'spark.eventLog.enabled' is set to
    true. For details see
    https://spark.apache.org/docs/latest/monitoring.html#:~:text=Note%20that%20this,to%20persisted%20storage.
    Open URL in Chrome to show relevant text already highlighted.
    The parameter "spark.history.fs.logDirectory" decides, where to persist log
    files for the UI to display

    :param app_name: Name of the application
    :return: SparkSession
    """
    # TODO: Enable Spark UI. Settings not correct yet, as UI closes after
    #  application finished
    spark: SparkSession = (
        SparkSession
            .builder
            .config("spark.jars", "src/lib/postgresql-42.3.3.jar")
            .config("spark.eventLog.enabled", "true")
            .config("spark.eventLog.dir",
                    "file:/Users/Kim/Documents/spark/history-server-logs")
            .config("spark.history.fs.logDirectory",
                    "file:/Users/Kim/Documents/spark/history-server-logs")
            .appName(app_name)
            .master("local[*]")
            .getOrCreate())
    spark.sparkContext.setLogLevel("ERROR")
    return spark


@task
def create_df_from_src(source_data: dict, spark: SparkSession) -> DataFrame:
    """transformation to retrieve source table from Google sheet

    :param source_data: dict
    :param spark: SparkSession
    :return: DataFrame
    """
    # extract values portion of sheet data, containing the table data minus any
    # API metadata and header
    tbl_data: list = source_data["values"][1:]
    # need to provide schema before df creation as it throws an error due to
    # wrong parsing fields with _n will be removed afterwards, first need to
    # read in all fields
    schema = StructType([
        StructField(s.TRADE_ID, StringType(), nullable=True),
        StructField("_2", StringType(), nullable=True),
        StructField(s.TICKER, StringType(), nullable=True),
        StructField(s.SHARE_AMOUNT, StringType(), nullable=True),
        StructField("_5", StringType(), nullable=True),
        StructField(s.ENTRY_DATE, StringType(), nullable=True),
        StructField(s.ENTRY_PRICE, StringType(), nullable=True),
        StructField(s.INITIAL_STOP_LOSS, StringType(), nullable=True),
        StructField("_9", StringType(), nullable=True),
        StructField(s.ADR_PERCENT, StringType(), nullable=True),
        StructField("_11", StringType(), nullable=True),
        StructField(s.MARKET_CAP, StringType(), nullable=True),
        StructField("_13", StringType(), nullable=True),
        StructField(s.PORTFOLIO_RISK, StringType(), nullable=True),
        StructField(s.SELL_SHARES_PRICE_1, StringType(), nullable=True),
        StructField(s.SELL_SHARES_AMOUNT_1, StringType(), nullable=True),
        StructField("_17", StringType(), nullable=True),
        StructField(s.SELL_SHARES_DATE_1, StringType(), nullable=True),
        StructField(s.SELL_SHARES_PRICE_2, StringType(), nullable=True),
        StructField(s.SELL_SHARES_AMOUNT_2, StringType(), nullable=True),
        StructField("_21", StringType(), nullable=True),
        StructField(s.SELL_SHARES_DATE_2, StringType(), nullable=True),
        StructField(s.SELL_SHARES_PRICE_3, StringType(), nullable=True),
        StructField(s.SELL_SHARES_AMOUNT_3, StringType(), nullable=True),
        StructField("_25", StringType(), nullable=True),
        StructField(s.SELL_SHARES_DATE_3, StringType(), nullable=True),
        StructField("_27", StringType(), nullable=True),
        StructField("_28", StringType(), nullable=True),
        StructField("_29", StringType(), nullable=True),
        StructField("_30", StringType(), nullable=True),
        StructField(s.TRELLO_TRADE_REVIEW, StringType(), nullable=True),
        StructField(s.SETUP_RATING, StringType(), nullable=True),
        StructField(s.SETUP_CHART, StringType(), nullable=True),
        StructField("_34", StringType(), nullable=True),
        StructField(s.SELL_DATETIME, StringType(), nullable=True)
    ])
    df = spark.createDataFrame(data=tbl_data, schema=schema)
    return df


@task
def drop_unneeded_cols(df: DataFrame) -> DataFrame:
    """Removes columns from source dataframe when they start with an _

    :param df: DataFrame
    :return: DataFrame
    """
    return df.drop('_2',
                   '_5',
                   '_9',
                   '_11',
                   '_13',
                   '_17',
                   '_21',
                   '_25',
                   '_27',
                   '_28',
                   '_29',
                   '_30',
                   '_34')


@task
def change_data_types(df: DataFrame) -> DataFrame:
    """Take initial dataframe and change data types into target Postgres format

    :param df: DataFrame
    :return: DataFrame
    """

    # define precision and scale for Decimal data type columns
    prec: int = 8
    sc: int = 4

    def ordinal_to_timestamp(ordinal_decimal: str) -> datetime:
        """Convert an ordinal decimal number to a datetime object for use in dataframes

        :param ordinal_decimal: unformatted string typically used in Google Sheets or Excel to represent a datetime e.g. 44358.494837962964
        :return: datetime
        """
        if ordinal_decimal > "0":
            epoch = datetime.strptime(EPOCH, "%Y-%m-%d")
            return epoch + timedelta(float(ordinal_decimal))
        # in case of no date provided in Google Sheets, which is represented as 1899-12-30,
        # set the date to unix epoch start date, otherwise overflow error gets thrown
        # see https://stackoverflow.com/questions/2518706/python-mktime-overflow-error
        else:
            return datetime(1970, 1, 1)

    # register function as UDF
    start_spark(app_name=APP_NAME).udf.register(
        "ordinal_to_timestamp", ordinal_to_timestamp, TimestampType())

    # convert to target data types
    df = (df.withColumn(s.TRADE_ID, F.col(s.TRADE_ID).cast(IntegerType()))
          .withColumn(s.SHARE_AMOUNT, F.col(s.SHARE_AMOUNT).cast(IntegerType()))
          # see accepted answer @ https://stackoverflow.com/questions/51830697/convert-date-from-integer-to-date-format
          # under 'Without using UDF'
          .withColumn(s.ENTRY_DATE,
                      F.expr(f"date_add('{EPOCH}', cast(entry_date as int))"))
          .withColumn(s.ENTRY_PRICE, F.col(s.ENTRY_PRICE)
                      .cast(DecimalType(precision=prec, scale=sc)))
          .withColumn(s.INITIAL_STOP_LOSS, F.col(s.INITIAL_STOP_LOSS)
                      .cast(DecimalType(precision=prec, scale=sc)))
          .withColumn(s.ADR_PERCENT, F.col(s.ADR_PERCENT)
                      .cast(DecimalType(precision=prec, scale=sc)))
          .withColumn(s.MARKET_CAP, F.col(s.MARKET_CAP)
                      .cast(DecimalType(precision=prec, scale=sc)))
          .withColumn(s.PORTFOLIO_RISK, F.col(s.PORTFOLIO_RISK)
                      .cast(DecimalType(precision=prec, scale=sc)))
          .withColumn(s.SELL_SHARES_PRICE_1, F.col(s.SELL_SHARES_PRICE_1)
                      .cast(DecimalType(precision=prec, scale=sc)))
          .withColumn(s.SELL_SHARES_AMOUNT_1, F.col(s.SELL_SHARES_AMOUNT_1)
                      .cast(IntegerType()))
          .withColumn(s.SELL_SHARES_DATE_1,
                      F.expr(f"date_add('{EPOCH}', cast({s.SELL_SHARES_DATE_1} as int))"))
          .withColumn(s.SELL_SHARES_PRICE_2, F.col(s.SELL_SHARES_PRICE_2)
                      .cast(DecimalType(precision=prec, scale=sc)))
          .withColumn(s.SELL_SHARES_AMOUNT_2, F.col(s.SELL_SHARES_AMOUNT_2)
                      .cast(IntegerType()))
          .withColumn(s.SELL_SHARES_DATE_2,
                      F.expr(f"date_add('{EPOCH}', cast({s.SELL_SHARES_DATE_2} as int))"))
          .withColumn(s.SELL_SHARES_PRICE_3, F.col(s.SELL_SHARES_PRICE_3)
                      .cast(DecimalType(precision=prec, scale=sc)))
          .withColumn(s.SELL_SHARES_AMOUNT_3,F.col(s.SELL_SHARES_AMOUNT_3)
                      .cast(IntegerType()))
          .withColumn(s.SELL_SHARES_DATE_3,
                      F.expr(f"date_add('{EPOCH}', cast({s.SELL_SHARES_DATE_3} as int))"))
          # UDF defined above
          .withColumn(s.SELL_DATETIME,
                      F.expr(f'ordinal_to_timestamp({s.SELL_DATETIME})')))
    return df


@task
def write_to_csv(df: DataFrame, path: str) -> None:
    df.toPandas().to_csv(path, sep=";", decimal=".", index=False)


@task
def run_tests(df1: DataFrame, df2: DataFrame, df3: DataFrame) -> None:
    df1.select(s.TICKER, s.ENTRY_DATE, s.SELL_SHARES_DATE_3,
               s.SELL_DATETIME).show(3, truncate=False)
    df2.select(s.TICKER, s.ENTRY_DATE, s.SELL_SHARES_DATE_3,
               s.SELL_DATETIME).show(3, truncate=False)
    df3.select(s.TICKER, s.ENTRY_DATE, s.SELL_SHARES_DATE_3,
               s.SELL_DATETIME).show(3, truncate=False)


def main() -> None:
    with Flow("trading-journal") as flow:
        # Spark entry point
        spark: SparkSession = start_spark(app_name=APP_NAME)

        # ============================
        # EXTRACT
        # ============================
        src_data: dict = gs.get_sheet_data()

        # ============================
        # TRANSFORM
        # ============================
        source_df: DataFrame = create_df_from_src(src_data, spark)
        df_drop_cols: DataFrame = drop_unneeded_cols(source_df)
        df_target_dtypes: DataFrame = change_data_types(df_drop_cols)

        # ============================
        # LOAD
        # ============================

        # target 1
        cpg.write_to_postgres(df_target_dtypes)

        # target 2
        # needed as source for tableau public
        # converted to Pandas, as native Spark 'DataFrame.write.csv()' method
        # creates weird name for csv (part-0000...)
        write_to_csv(df_target_dtypes, path="data-out/trading_journal.csv")

        # target 3
        # needed as source for tableau public
        # gets data from trading journal view and saves in csv
        cpg.pg_table_to_csv(table= "v_trading_journal", upstream_tasks=[cpg.write_to_postgres])
        cpg.pg_table_to_csv(table= "v_return_monthly_by_sell_date", upstream_tasks=[cpg.write_to_postgres])
        cpg.pg_table_to_csv(table= "v_win_rate_cumulative", upstream_tasks=[cpg.write_to_postgres])

        # ============================
        # TESTS
        # ============================
        run_tests(source_df, df_drop_cols, df_target_dtypes)

    flow_state: st.State = flow.run()
    flow.visualize(flow_state=flow_state)


if __name__ == "__main__":
    main()
