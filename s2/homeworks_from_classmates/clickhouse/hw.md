```text
docker exec -it clickhouse-hw clickhouse-client
docker exec -it postgres-hw psql -U postgres
```
# Задание 1

## Готовая таблица + данные

```sql
	CREATE TABLE web_logs (
    log_time DateTime,
    ip String,
    url String,
    status_code UInt16,
    response_size UInt64
	) ENGINE = MergeTree()
	ORDER BY (log_time, status_code);
```

```sql
	INSERT INTO web_logs
	SELECT
    toDateTime('2024-03-01 00:00:00') + INTERVAL number SECOND,
    concat('192.168.0.', toString(number % 50)),
    arrayElement(['/home', '/api/users', '/api/orders', '/admin', '/products'], number % 5 + 1),
    arrayElement([200, 200, 200, 404, 500, 301, 200], number % 7 + 1),
    rand() % 1000000
	FROM numbers(500000);
```

## Таски

1. Найдите топ-10 IP-адресов по количеству запросов.
```sql
SELECT ip, count() AS request_count
FROM web_logs
GROUP BY ip
ORDER BY request_count DESC
LIMIT 10;
```

```text
Query id: 9d52a84b-ab52-4134-a145-392b57adfb51

    ┌─ip───────────┬─request_count─┐                                                                                                                                                                 
 1. │ 192.168.0.48 │         10000 │
 2. │ 192.168.0.22 │         10000 │
 3. │ 192.168.0.8  │         10000 │
 4. │ 192.168.0.11 │         10000 │
 5. │ 192.168.0.46 │         10000 │
 6. │ 192.168.0.37 │         10000 │
 7. │ 192.168.0.18 │         10000 │
 8. │ 192.168.0.1  │         10000 │
 9. │ 192.168.0.0  │         10000 │
10. │ 192.168.0.43 │         10000 │
    └──────────────┴───────────────┘
10 rows in set. Elapsed: 0.010 sec. Processed 500.00 thousand rows, 7.40 MB (51.68 million rows/s., 764.85 MB/s.)
Peak memory usage: 8.46 MiB.
```

2. Посчитайте процент успешных запросов (2xx) и ошибочных (4xx, 5xx).
```sql
SELECT 
    round(countIf(status_code >= 200 AND status_code <= 299) / count() * 100, 2) AS success_percent,
    round(countIf(status_code >= 400 AND status_code <= 599) / count() * 100, 2) AS error_percent
FROM web_logs;
```

```text
Query id: 8b614822-ab13-4c30-8c47-79d539da18ad

   ┌─success_percent─┬─error_percent─┐                                                                                                                                                               
1. │           57.14 │         28.57 │
   └─────────────────┴───────────────┘

1 row in set. Elapsed: 0.008 sec. Processed 500.00 thousand rows, 1.00 MB (62.73 million rows/s., 125.46 MB/s.)
Peak memory usage: 1.13 MiB.
```

3. Найдите самый популярный URL и средний размер ответа для него.
```sql
SELECT url, count() AS hits, avg(response_size) AS avg_size
FROM web_logs
GROUP BY url
ORDER BY hits DESC
LIMIT 1;
```

```text
Query id: 27ced5a9-9f30-4ff7-9eb9-fe98478ce6ff

   ┌─url───┬───hits─┬─────avg_size─┐                                                                                                                                                                 
1. │ /home │ 100000 │ 500086.77737 │
   └───────┴────────┴──────────────┘

1 row in set. Elapsed: 0.014 sec. Processed 500.00 thousand rows, 9.60 MB (36.43 million rows/s., 699.34 MB/s.)
Peak memory usage: 11.37 MiB.
```

4. Определите час с наибольшим количеством ошибок 500.
```sql
SELECT toStartOfHour(log_time) AS error_hour, count() AS error_count
FROM web_logs
WHERE status_code = 500
GROUP BY error_hour
ORDER BY error_count DESC
LIMIT 1;
```

```text
Query id: 8a48f975-797f-438b-b0d0-0298846cf151

   ┌──────────error_hour─┬─error_count─┐                                                                                                                                                             
1. │ 2024-03-05 07:00:00 │         515 │
   └─────────────────────┴─────────────┘

1 row in set. Elapsed: 0.009 sec. Processed 500.00 thousand rows, 3.00 MB (55.08 million rows/s., 330.49 MB/s.)
Peak memory usage: 1.56 MiB.
```

# Задание 2

## Сравнение с PostgreSQL

```sql
	CREATE TABLE sales_ch (
    sale_date DateTime,
    product_id UInt64,
    category String,
    quantity UInt32,
    price Float64,
    customer_id UInt64
	) ENGINE = MergeTree()
	ORDER BY (sale_date);

	INSERT INTO sales_ch
	SELECT
    toDateTime('2024-01-01 00:00:00') + INTERVAL number MINUTE,
    number % 1000,
    arrayElement(['Electronics', 'Clothing', 'Food', 'Books'], number % 4 + 1),
    rand() % 10 + 1,
    round(rand() % 10000 / 100, 2),
    number % 50000
	FROM numbers(1000000);
```

```sql
	CREATE TABLE sales_pg (
    sale_date timestamp,
    product_id bigint,
    category text,
    quantity integer,
    price float8,
    customer_id bigint
	);

	CREATE INDEX idx_sales_pg_date ON sales_pg(sale_date);
	CREATE INDEX idx_sales_pg_product ON sales_pg(product_id);

	INSERT INTO sales_pg
	SELECT
    '2024-01-01 00:00:00'::timestamp + (n || ' minutes')::interval,
    n % 1000,
    CASE (n % 4)
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Clothing'
        WHEN 2 THEN 'Food'
        ELSE 'Books'
    END,
    (random() * 9 + 1)::integer,
    round((random() * 100)::numeric, 2),
    n % 50000
	FROM generate_series(1, 1000000) AS n;
```

## Выполните замеры и сделайте выводы

### Запросы

1. Продажи за последний месяц (например, февраль 2024)

**В ClickHouse:**
```sql
SELECT category, sum(quantity * price) AS total_revenue
FROM sales_ch
WHERE sale_date >= '2024-02-01' AND sale_date < '2024-03-01'
GROUP BY category;
```

```text
Query id: 33d13bc6-798c-45ce-852b-182ef1ed5514

   ┌─category────┬──────total_revenue─┐                                                                                                                                                              
1. │ Books       │  2882030.620000002 │ -- 2.88 million
2. │ Clothing    │ 2904433.3400000082 │ -- 2.90 million
3. │ Food        │  2863024.920000001 │ -- 2.86 million
4. │ Electronics │ 2849765.8399999947 │ -- 2.85 million
   └─────────────┴────────────────────┘

4 rows in set. Elapsed: 0.011 sec. Processed 49.15 thousand rows, 1.28 MB (4.60 million rows/s., 119.62 MB/s.)
Peak memory usage: 1.90 MiB.
```

**В PostgreSQL:**
```sql
SELECT category, sum(quantity * price) AS total_revenue
FROM sales_pg
WHERE sale_date >= '2024-02-01' AND sale_date < '2024-03-01'
GROUP BY category;
```

```text
postgres=# SELECT category, sum(quantity * price) AS total_revenue
FROM sales_pg
WHERE sale_date >= '2024-02-01' AND sale_date < '2024-03-01'
GROUP BY category;

  category   |   total_revenue    
-------------+--------------------
 Electronics |  2837794.700000016
 Food        |  2880613.559999985
 Clothing    | 2831975.9500000053
 Books       | 2868110.7500000065
(4 rows)
```

2. Размер данных

**В ClickHouse:**
```sql
SELECT table, formatReadableSize(total_bytes) AS size
FROM system.tables 
WHERE name = 'sales_ch';
```

```text
Query id: add8a00b-f966-4287-b8a5-58f96b50238a

   ┌─table────┬─size──────┐                                                                                                                                                                          
1. │ sales_ch │ 14.88 MiB │
   └──────────┴───────────┘

1 row in set. Elapsed: 0.003 sec.
```

**В PostgreSQL:**
```sql
SELECT pg_size_pretty(pg_total_relation_size('sales_pg'));
```

```text
postgres=# SELECT pg_size_pretty(pg_total_relation_size('sales_pg'));
 pg_size_pretty
----------------
 102 MB
(1 row)
```

## Ответьте на вопросы:

1. Какая СУБД быстрее вставила 1 млн строк?
> **ClickHouse.** Он спроектирован для массовой вставки (bulk inserts). Данные пишутся большими кусками (партиями) прямо на диск в неизменяемые куски (parts) движком `MergeTree`. PostgreSQL при вставке тратит много ресурсов на поддержание транзакционности (MVCC), запись в журнал упреждающей записи (WAL) и обновление B-Tree индексов для каждой строки.

2. Во сколько раз ClickHouse сжал данные эффективнее?
> **В 7 раз эффективнее**. Причина в **колоночном хранении**. В колонке `category` лежат подряд миллионы одинаковых строк (`Electronics`, `Food` и т.д.). Алгоритмам сжатия (LZ4/ZSTD) невероятно легко сжимать повторяющиеся данные одного типа. PostgreSQL хранит данные построчно, что сжимается гораздо хуже.

3. Какой вывод можно сделать о выборе СУБД для аналитики?
> Для аналитики (чтение миллионов строк, агрегации `SUM`, `AVG`, `GROUP BY`, построение дашбордов) **нужно выбирать ClickHouse** (или аналогичные OLAP-решения). PostgreSQL отлично подходит для бэкенда приложения, где важны транзакции, точечное чтение/запись по ID (CRUD) и строгая консистентность.

4. Разница ClickHouse и PostgreSQL
> *   **Архитектура:** ClickHouse — колоночная (читает только нужные колонки), PostgreSQL — строчная (читает строку целиком).
> *   **Тип нагрузки:** ClickHouse — **OLAP** (аналитика). PostgreSQL — **OLTP** (транзакции).
> *   **Индексы:** В PostgreSQL B-Tree индексы указывают на конкретные строки. В ClickHouse разреженные (sparse) индексы указывают на блоки данных (гранулы), быстро отсекая гигабайты ненужной информации.
> *   **Изменения:** В PostgreSQL легко делать `UPDATE` и `DELETE` конкретных строк. В ClickHouse это тяжелые асинхронные операции (мутации), систему нужно использовать как "только для добавления" (append-only).

# Задние 3

Потыкаться в http://localhost:8123, посмотреть dashboard


UI ClickHouse (Play UI).
Удобный интерфейс для написания запросов.
Метрики выполнения в правом нижнем углу после запуска запроса (сколько миллионов строк в секунду просканировал движок — там будут космические цифры вроде `1.5 GB/s`, `10M rows/s`).
История запросов. Отличный инструмент для быстрых тестов без терминала.