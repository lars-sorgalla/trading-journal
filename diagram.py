from diagrams import Diagram
from diagrams.programming.flowchart import Document
from diagrams.onprem.analytics import Spark, Tableau
from diagrams.onprem.database import Postgresql


with Diagram("Architecture Of Trading Journal Program",
             show=True, direction="LR"):
    gsheet = Document("Google Sheet")
    spark = Spark("Transformation")
    postgres = Postgresql("DB 'trading-journal'")
    csv = Document("CSVs")
    tableau = Tableau("Dashboards")

    gsheet >> spark
    spark >> [csv, postgres]
    csv >> tableau
