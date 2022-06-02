from diagrams import Cluster, Diagram
from diagrams.programming.flowchart import Document
from diagrams.onprem.analytics import Spark, Tableau
from diagrams.onprem.database import Postgresql

with Diagram("Application Architecture", show=True, direction="LR", ):
    gsheet = Document("Google Sheet")
    spark = Spark("transformation")
    tableau = Tableau("dashboards")
    postgres = Postgresql("database")
    csv = Document("CSVs")

    gsheet >> spark >> postgres >> csv >> tableau
