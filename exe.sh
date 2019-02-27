#!/usr/bin/env bash

sudo apt install default-libmysqlclient-dev
export AIRFLOW_GPL_UNIDECODE=yes
pip install -r requirements.txt
mkdir -p airflow_home/dags
export AIRFLOW_HOME=$(pwd)/airflow_home
AIRFLOW_CONFIG=$AIRFLOW_HOME/airflow.cfg
cd  airflow_home
airflow initdb
