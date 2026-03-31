## 1. Секционирование: RANGE / LIST / HASH

Для тестирования механизмов секционирования была создана схема `part_test` и три таблицы с различными типами партицирования: `RANGE`, `LIST` и `HASH`. Ключи секционирования были включены в состав первичного ключа (PRIMARY KEY) согласно архитектурным требованиям PostgreSQL

**Скрипт создания таблиц и генерации тестовых данных (по 10 000 строк):**
```sql
DROP SCHEMA IF EXISTS part_test CASCADE;
CREATE SCHEMA part_test;

-- 1. RANGE (Секционирование по диапазону дат)
CREATE TABLE part_test.orders_range (
id serial,
order_date date NOT NULL,
amount numeric,
PRIMARY KEY (id, order_date)
) PARTITION BY RANGE (order_date);

CREATE TABLE part_test.orders_range_2023 PARTITION OF part_test.orders_range FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
CREATE TABLE part_test.orders_range_2024 PARTITION OF part_test.orders_range FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

INSERT INTO part_test.orders_range (order_date, amount)
SELECT '2023-05-01'::date + (random() * 365)::integer, random() * 1000
FROM generate_series(1, 10000);

-- 2. LIST (Секционирование по списку городов)
CREATE TABLE part_test.users_list (
id serial,
city text NOT NULL,
name text,
PRIMARY KEY (id, city)
) PARTITION BY LIST (city);

CREATE TABLE part_test.users_list_msk PARTITION OF part_test.users_list FOR VALUES IN ('MSK');
CREATE TABLE part_test.users_list_spb PARTITION OF part_test.users_list FOR VALUES IN ('SPB');

INSERT INTO part_test.users_list (city, name)
SELECT CASE WHEN random() > 0.5 THEN 'MSK' ELSE 'SPB' END, 'User ' || gs
FROM generate_series(1, 10000) AS gs;

-- 3. HASH (Секционирование по остатку от деления ID)
CREATE TABLE part_test.logs_hash (
id serial,
message text,
PRIMARY KEY (id)
) PARTITION BY HASH (id);

CREATE TABLE part_test.logs_hash_0 PARTITION OF part_test.logs_hash FOR VALUES WITH (MODULUS 3, REMAINDER 0);
CREATE TABLE part_test.logs_hash_1 PARTITION OF part_test.logs_hash FOR VALUES WITH (MODULUS 3, REMAINDER 1);
CREATE TABLE part_test.logs_hash_2 PARTITION OF part_test.logs_hash FOR VALUES WITH (MODULUS 3, REMAINDER 2);

INSERT INTO part_test.logs_hash (message)
SELECT 'Log entry ' || gs
FROM generate_series(1, 10000) AS gs;
```

### 1.1. RANGE-секционирование
**Запрос:** 
```sql
EXPLAIN ANALYZE SELECT * FROM part_test.orders_range WHERE order_date = '2023-08-15';
```

**План выполнения:**
```text
Seq Scan on orders_range_2023 orders_range  (cost=0.00..126.85 rows=35 width=19) (actual time=0.016..0.290 rows=35 loops=1)
Filter: (order_date = '2023-08-15'::date)
Rows Removed by Filter: 6673
Planning Time: 0.389 ms
Execution Time: 0.328 ms
```

**Анализ:**
* **a. Есть ли partition pruning?** Да. Планировщик отсек ненужные секции на основе условия в `WHERE`. Сканирование происходит только внутри целевой секции за 2023 год.
* **b. Сколько партиций участвует в плане?** 1 партиция (`orders_range_2023`).
* **c. Используется ли индекс?** Нет (`Seq Scan`). Индекс не был использован, так как планировщик счел последовательное чтение небольшой секции более оптимальным планом, чем обращение к индексу.

### 1.2. LIST-секционирование
**Запрос:** 
```sql
EXPLAIN ANALYZE SELECT * FROM part_test.users_list WHERE city = 'MSK';
```

**План выполнения:**
```text
Seq Scan on users_list_msk users_list  (cost=0.00..94.79 rows=5023 width=17) (actual time=0.007..0.462 rows=5023 loops=1)
Filter: (city = 'MSK'::text)
Planning Time: 0.229 ms
Execution Time: 0.615 ms
```

**Анализ:**
* **a. Есть ли partition pruning?** Да. Из плана исключена секция `SPB`, чтение идет строго по партиции Москвы.
* **b. Сколько партиций участвует в плане?** 1 партиция (`users_list_msk`).
* **c. Используется ли индекс?** Нет (`Seq Scan`). Поскольку запрос возвращает примерно 50% всех данных целевой секции (5023 строки), оптимизатор PostgreSQL выбирает последовательное чтение (`Seq Scan`), так как массовое чтение страниц с диска эффективнее.

### 1.3. HASH-секционирование
**Запрос:** 
```sql
EXPLAIN ANALYZE SELECT * FROM part_test.logs_hash WHERE id = 500;
```

**План выполнения:**

```text
Index Scan using logs_hash_0_pkey on logs_hash_0 logs_hash  (cost=0.28..8.30 rows=1 width=18) (actual time=0.017..0.017 rows=1 loops=1)
Index Cond: (id = 500)
Planning Time: 0.194 ms
Execution Time: 0.029 ms
```

**Анализ:**
* **a. Есть ли partition pruning?** Да. PostgreSQL вычислил хэш для `id = 500` и определил, что данные лежат в нулевой секции, проигнорировав остальные.
* **b. Сколько партиций участвует в плане?** 1 партиция (`logs_hash_0`).
* **c. Используется ли индекс?** Да (`Index Scan`). Поскольку запрашивается ровно одна уникальная строка, оптимизатор задействовал сканирование по первичному ключу (`logs_hash_0_pkey`).

## 2. Секционирование и физическая репликация

### a. Проверка наличия секционирования на репликах
Для проверки того, перенеслась ли структура секций на ведомый сервер, было выполнено подключение к физической реплике (`replica1`) и запрошено описание структуры таблицы `orders_range`:

**Запрос:**
```bash
docker exec -it replica1 psql -U postgres -d marketplace_db -c "d+ part_test.orders_range"
```

**Вывод консоли:**
```text
Partitioned table "part_test.orders_range"
Column   |  Type   | Collation | Nullable |                     Default                      | Storage | Compression | Stats target | Description
------------+---------+-----------+----------+----------------------------------------------------+---------+-------------+--------------+-------------
id         | integer |           | not null | nextval('part_test.orders_range_id_seq'::regclass) | plain   |             |              |
order_date | date    |           | not null |                                                    | plain   |             |              |
amount     | numeric |           |          |                                                    | main    |             |              |
Partition key: RANGE (order_date)
Indexes:
"orders_range_pkey" PRIMARY KEY, btree (id, order_date)
Partitions: part_test.orders_range_2023 FOR VALUES FROM ('2023-01-01') TO ('2024-01-01'),
part_test.orders_range_2024 FOR VALUES FROM ('2024-01-01') TO ('2025-01-01')
```
Вывод подтверждает, что физическая реплика содержит абсолютно идентичную Мастеру структуру: все партиции, составной первичный ключ и правила распределения (Partition key) перенеслись корректно.

### b. Почему репликация “не знает” про секции?
Физическая репликация создаёт полную побайтовую копию базы данных на STAND BY-сервере. Она работает на самом низком уровне — передает блоки данных через журнал транзакций (WAL) и применяет их к файлам на диске реплики.

С точки зрения процесса физической репликации таких логических абстракций, как "таблицы" или "секции", не существует. Поскольку в PostgreSQL каждая секция (партиция) под капотом является отдельным физическим файлом в файловой системе, репликация просто "вслепую" копирует байты внутри этих файлов. Ей не нужно анализировать логику декларативного секционирования, поэтому всё переносится автоматически и без дополнительных настроек.

## 3. Логическая репликация и секционирование (publish_via_partition_root = on / off)

Для демонстрации работы параметра `publish_via_partition_root` на стороне логической реплики (`replica2`) была создана обычная (несекционированная) таблица `part_test.orders_range`, выступающая в роли приемника данных.

### Сценарий 1: Успешная репликация (publish_via_partition_root = ON)
В данном режиме все изменения транслируются через основную (родительскую) таблицу.
**Создание публикации (на Мастере):**
```sql
CREATE PUBLICATION pub_part_on FOR TABLE part_test.orders_range WITH (publish_via_partition_root = on);
```
**Создание подписки (на Реплике):**
```sql
CREATE SUBSCRIPTION sub_part_on CONNECTION '...' PUBLICATION pub_part_on;
```
**Результат:** Подписка создана успешно. Реплика без проблем принимает данные в свою монолитную таблицу `orders_range`, так как изменения приходят от имени родительской таблицы, и Реплике неважно, как структура секционирована на стороне публикатора.

---

### Сценарий 2: Ошибка репликации (publish_via_partition_root = OFF)
В режиме по умолчанию (`OFF`) команды приходят на подписчика с названием той конкретной физической секции, в которую попала строка на Мастере.
**Создание публикации (на Мастере):**
```sql
CREATE PUBLICATION pub_part_off FOR TABLE part_test.orders_range WITH (publish_via_partition_root = off);
```
**Попытка создания подписки (на Реплике):**
```sql
CREATE SUBSCRIPTION sub_part_off CONNECTION 'host=postgres port=5432 user=postgres password=qwerty007 dbname=marketplace_db' PUBLICATION pub_part_off;
```
**Результат (Ошибка):**
```text
[42P01] ERROR: relation "part_test.orders_range_2024" does not exist
```
**Анализ:** При попытке первичной синхронизации данных (initial sync) Мастер передал подписчику список физических таблиц-секций для копирования (например, `orders_range_2024`). Поскольку на стороне Реплики таких специфичных таблиц не существует (создана только родительская), процесс репликации немедленно завершился с ошибкой отсутствия отношения (relation does not exist).

***

## 4. Шардирование через postgres_fdw

Для реализации горизонтального масштабирования (шардирования) была использована технология **Foreign Data Wrapper (FDW)** в сочетании с декларативным секционированием.

### 4.1. Архитектура решения
В данной конфигурации мы распределили роли между тремя контейнерами:
* **`primary`** — выступает в роли **Роутера**. На нем нет физических данных, он лишь перенаправляет запросы.
* **`replica1`** — стал **Шардом 1**. Хранит данные пользователей из региона `RU`.
* **`replica2`** — стал **Шардом 2**. Хранит данные пользователей из региона `US`.

### 4.2. Настройка компонентов

**Шаг 1: Подготовка независимых шардов**
Поскольку `replica1` изначально была физической репликой (Read-Only), мы перевели её в режим полноценной независимой базы:
```sql
SELECT pg_promote();
```

**Шаг 2: Создание физических таблиц на узлах-шардах**
На каждом шарде создана локальная схема и таблица с ограничением `CHECK` для обеспечения целостности данных. Каждая таблица заполнена 5 000 строк.

**Шаг 3: Настройка Роутера (Магия FDW)**
На главном узле (`primary`) выполнена настройка внешних серверов и маппинга пользователей. Главная фишка решения: **удаленные таблицы подключены как секции локальной таблицы-пустышки**:
```sql
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Подключение удаленных серверов
CREATE SERVER shard1_server FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'replica1', port '5432', dbname 'marketplace_db');
CREATE SERVER shard2_server FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'replica2', port '5432', dbname 'marketplace_db');

-- Создание родительской таблицы-роутера
CREATE TABLE sharding.users_router (id integer, name text, country text) PARTITION BY LIST (country);

-- Привязка внешних шардов как партиций
CREATE FOREIGN TABLE sharding.users_ru PARTITION OF sharding.users_router FOR VALUES IN ('RU') SERVER shard1_server OPTIONS (schema_name 'sharding', table_name 'users_ru');
CREATE FOREIGN TABLE sharding.users_us PARTITION OF sharding.users_router FOR VALUES IN ('US') SERVER shard2_server OPTIONS (schema_name 'sharding', table_name 'users_us');
```

---

### 4.3. Тестирование и анализ планов запросов

#### **Запрос 1: Получение всех данных (сканирование всего кластера)**
`EXPLAIN ANALYZE SELECT * FROM sharding.users_router;`

**План выполнения:**
```text
Append  (cost=100.00..620.50 rows=1780 width=68) (actual time=1.371..20.925 rows=10000 loops=1)
  ->  Foreign Scan on users_ru users_router_1  (cost=100.00..305.80 rows=890 width=68) (actual time=1.370..10.846 rows=5000 loops=1)
  ->  Foreign Scan on users_us users_router_2  (cost=100.00..305.80 rows=890 width=68) (actual time=1.561..9.249 rows=5000 loops=1)
Planning Time: 0.285 ms
Execution Time: 46.116 ms
```
**Анализ:** Планировщик видит, что данные распределены. Он использует узел `Append`, чтобы объединить результаты двух `Foreign Scan`. Роутер параллельно (или последовательно) обратился к `replica1` и `replica2`, собрал 10 000 строк и отдал их пользователю.

#### **Запрос 2: Точечный запрос на конкретный шард**
`EXPLAIN ANALYZE SELECT * FROM sharding.users_router WHERE country = 'RU';`

**План выполнения:**
```text
Foreign Scan on users_ru users_router  (cost=100.00..121.97 rows=4 width=68) (actual time=0.837..12.540 rows=5000 loops=1)
Planning Time: 0.227 ms
Execution Time: 13.217 ms
```
**Анализ:** 
Здесь сработал механизм **Partition Pruning**. База поняла, что запрашиваемый регион `RU` находится только на первом шарде. Поход на второй сервер (`replica2`) был исключен из плана. 
Выполнен один единственный `Foreign Scan`, что значительно экономит ресурсы сети и удаленных узлов.


