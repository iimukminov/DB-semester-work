from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import requests
import pandas as pd
import psycopg2

# Подключение к PostgreSQL (используем имя контейнера из docker-compose)
PG_URL = "dbname='marketplace_db' user='postgres' host='postgres-primary' password='qwerty007'"

def load_pvz_from_csv():
    """Источник 1: Читаем CSV и грузим пункты выдачи в PostgreSQL"""
    df = pd.read_csv('/opt/airflow/data/new_pvz.csv')
    conn = psycopg2.connect(PG_URL)
    cur = conn.cursor()

    for _, row in df.iterrows():
        # Идемпотентность
        cur.execute("""
            INSERT INTO marketplace.pvz (address)
            VALUES (%s) ON CONFLICT (address) DO NOTHING;
        """, (row['address'],))

    conn.commit()
    cur.close()
    conn.close()

def load_items_from_api():
    """Источник 2: Забираем товары из Dummy API и грузим в PostgreSQL"""
    response = requests.get('https://dummyjson.com/products?limit=10').json()

    conn = psycopg2.connect(PG_URL)
    cur = conn.cursor()

    # Создаем заглушки для внешних ключей, чтобы БД не ругалась
    cur.execute("INSERT INTO marketplace.category_of_item (category_id, name) VALUES (999, 'Imported APIs') ON CONFLICT (category_id) DO NOTHING;")
    cur.execute("INSERT INTO marketplace.workers (worker_id, login, password_hash, salt) VALUES (999, 'api_bot', 'hash', 'salt') ON CONFLICT (worker_id) DO NOTHING;")
    cur.execute("INSERT INTO marketplace.shops (shop_id, owner_id, name) VALUES (999, 999, 'API Global Store') ON CONFLICT (shop_id) DO NOTHING;")

    for item in response['products']:
        cur.execute("""
            INSERT INTO marketplace.items (shop_id, name, description, category_id, price)
            VALUES (999, %s, %s, 999, %s)
            ON CONFLICT DO NOTHING;
        """, (item['title'], item['description'], item['price']))

    conn.commit()
    cur.close()
    conn.close()

# Описание DAG
with DAG(
    dag_id='01_marketplace_etl_sources',
    start_date=datetime(2026, 1, 1),
    schedule_interval='@daily',
    catchup=False,
    tags=['ETL', 'Postgres']
) as dag:

    task_csv = PythonOperator(
        task_id='load_csv_pvz',
        python_callable=load_pvz_from_csv
    )

    task_api = PythonOperator(
        task_id='load_api_items',
        python_callable=load_items_from_api
    )

    [task_csv, task_api] # Запускаются параллельно