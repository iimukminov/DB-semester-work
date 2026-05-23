from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import psycopg2
from clickhouse_driver import Client

PG_URL = "dbname='marketplace_db' user='postgres' host='postgres-primary' password='qwerty007'"

def transfer_data_to_clickhouse():
    # 1. Извлекаем (Extract) обогащенные данные из PostgreSQL
    pg_conn = psycopg2.connect(PG_URL)
    pg_cur = pg_conn.cursor()

    # Собираем денормализованную строку.
    # В реальном DWH тут было бы WHERE DATE(purchase_date) = CURRENT_DATE, но для ДЗ берем всё.
    pg_cur.execute("""
        SELECT
            p.purchase_id,
            p.purchase_date,
            i.name as item_name,
            c.name as category_name,
            s.name as shop_name,
            pvz.address as pvz_address,
            p.quantity,
            COALESCE(p.total_price, i.price * p.quantity) as total_price,
            p.status
        FROM marketplace.purchases p
        JOIN marketplace.items i ON p.item_id = i.item_id
        JOIN marketplace.category_of_item c ON i.category_id = c.category_id
        JOIN marketplace.shops s ON i.shop_id = s.shop_id
        JOIN marketplace.orders o ON p.purchase_id = o.purchase_id
        JOIN marketplace.pvz pvz ON o.pvz_id = pvz.pvz_id;
    """)
    rows = pg_cur.fetchall()
    pg_conn.close()

    if not rows:
        print("Нет данных для загрузки в ClickHouse.")
        return

    # 2. Загружаем (Load) в ClickHouse
    ch_client = Client(host='clickhouse-hw', user='default', password='password')

    # Вставляем новые данные
    ch_client.execute(
        'INSERT INTO default.fact_sales_wide VALUES',
        rows
    )
    print(f"Успешно загружено {len(rows)} строк в ClickHouse.")

with DAG(
    dag_id='02_marketplace_postgres_to_clickhouse',
    start_date=datetime(2026, 1, 1),
    schedule_interval='@daily',
    catchup=False,
    tags=['Analytics', 'ClickHouse']
) as dag:

    transfer_task = PythonOperator(
        task_id='pg_to_ch_migration',
        python_callable=transfer_data_to_clickhouse
    )