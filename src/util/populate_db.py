from src.job.connect_postgres import connect

import pyodbc


def insert_sectors() -> None:
    """
    Fill all tickers from Google sheet into stock_sectors table as an
    incremental load

    :return: None
    """
    # create connection
    connection = connect()
    cursor = connection.cursor()

    # get tickers to be used for populating sectors table. Returned Row
    # object is a sequence of tuple-like elements e.g. [('CLF', )('HIVE', )...]
    rows: pyodbc.Row = (cursor
                        .execute(f"SELECT DISTINCT ticker "
                                 f"FROM ods.v_trading_journal")
                        .fetchall())

    # insert into table
    for row in rows:
        cursor.execute(f"INSERT INTO ods.stock_sectors (ticker) VALUES (?)",
                       row[0])
        cursor.commit()


# used for single execution, not used in the main program
if __name__ == '__main__':
    insert_sectors()
