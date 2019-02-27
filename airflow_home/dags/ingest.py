#!/usr/bin/env python

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from airflow.operators.python_operator import PythonOperator
the_past = datetime.combine(datetime.today() - timedelta(1),\
        datetime.min.time())

default_args = {
        'owner': 'airflow',
        'depends_on_past': False,
        'start_date': the_past,
        'email_on_failure': False,
        'email_on_retry': False,
        'concurrency': 1,
        'retry_delay': timedelta(minutes=5),
        'retries': 0
        }

dag = DAG('simple', default_args=default_args,\
        schedule_interval='0 0 10 * *')

opr_ingest = BashOperator(
        task_id='ingest',
        bash_command='python \
        /home/ollin/Documentos/migration/src/ingest/asylum_seekers.py',
        dag = dag)

opr_delimiter = BashOperator(
        task_id='delimiter',
        bash_command='sh \
        /home/ollin/Documentos/migration/src/ingest/delimiter.sh ',
        dag = dag)

opr_ingest >> opr_delimiter
