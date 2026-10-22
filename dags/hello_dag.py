from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator


def say_hello():
    print("Hello from Composer, deployed via Terraform + gcloud")


with DAG(
    dag_id="hello_dag",
    start_date=datetime(2026, 10, 1),
    schedule=None,
    catchup=False,
    tags=["week3", "test"],
) as dag:
    start = BashOperator(task_id="start", bash_command="echo starting")
    hello = PythonOperator(task_id="hello", python_callable=say_hello)

    start >> hello