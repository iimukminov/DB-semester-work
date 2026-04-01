Задание 1

```text
1. До:
Seq Scan on exam_events  (cost=0.00..1617.07 rows=1 width=26) (actual time=3.552..3.554 rows=3 loops=1)
  Filter: ((created_at >= '2025-03-10 00:00:00'::timestamp without time zone) AND (created_at < '2025-03-11 00:00:00'::timestamp without time zone) AND (user_id = 4242))
  Rows Removed by Filter: 60001
  Buffers: shared hit=567
Planning:
  Buffers: shared hit=46
Planning Time: 0.276 ms
Execution Time: 3.573 ms

2. - Seq scan
   - CREATE INDEX idx_exam_events_status ON exam_events (status);
     CREATE INDEX idx_exam_events_amount_hash ON exam_events USING hash (amount);
   - Потому, что запрос WHERE не только по PK и два других не используются
   
3. B-tree: CREATE INDEX idx_created_at_btree ON exam_events (created_at);

4. Bitmap Heap Scan on exam_events  (cost=14.85..621.35 rows=1 width=26) (actual time=0.961..0.964 rows=3 loops=1)
  Recheck Cond: ((created_at >= '2025-03-10 00:00:00'::timestamp without time zone) AND (created_at < '2025-03-11 00:00:00'::timestamp without time zone))
  Filter: (user_id = 4242)
  Rows Removed by Filter: 666
  Heap Blocks: exact=567
  Buffers: shared hit=567 read=4
  ->  Bitmap Index Scan on idx_created_at_btree  (cost=0.00..14.85 rows=656 width=0) (actual time=0.104..0.104 rows=669 loops=1)
        Index Cond: ((created_at >= '2025-03-10 00:00:00'::timestamp without time zone) AND (created_at < '2025-03-11 00:00:00'::timestamp without time zone))
        Buffers: shared read=4
Planning:
  Buffers: shared hit=17 read=1
Planning Time: 0.420 ms
Execution Time: 0.985 ms

5. Изменилось ВСЁ, теперь используется индекс для поиска по датам, и затем отсекает по id

6. надо
```

Задание 2

```text
1. Hash Join  (cost=557.80..1696.67 rows=343 width=25) (actual time=8.222..13.586 rows=1000 loops=1)
  Hash Cond: (o.user_id = u.id)
  Buffers: shared hit=1165 read=21
  ->  Bitmap Heap Scan on exam_orders o  (cost=147.30..1268.02 rows=6915 width=22) (actual time=6.048..10.215 rows=7000 loops=1)
        Recheck Cond: ((created_at >= '2025-03-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-03-08 00:00:00'::timestamp without time zone))
        Heap Blocks: exact=1017
        Buffers: shared hit=1017 read=21
        ->  Bitmap Index Scan on idx_exam_orders_created_at  (cost=0.00..145.57 rows=6915 width=0) (actual time=5.864..5.865 rows=7000 loops=1)
              Index Cond: ((created_at >= '2025-03-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-03-08 00:00:00'::timestamp without time zone))
              Buffers: shared read=21
  ->  Hash  (cost=398.00..398.00 rows=1000 width=11) (actual time=2.159..2.161 rows=1000 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 50kB
        Buffers: shared hit=148
        ->  Seq Scan on exam_users u  (cost=0.00..398.00 rows=1000 width=11) (actual time=0.044..2.004 rows=1000 loops=1)
              Filter: (country = 'JP'::text)
              Rows Removed by Filter: 19000
              Buffers: shared hit=148
Planning:
  Buffers: shared hit=79
Planning Time: 1.132 ms
Execution Time: 13.684 ms

2. Хеш джоин

3. Одна таблица маленькая и по ней строиться хеш таблица

4. CREATE INDEX idx_exam_users_name ON exam_users (name); в запросе не используется
   мб еще CREATE INDEX idx_exam_orders_created_at ON exam_orders (created_at); если очень много затрагивает диапазон

5. CREATE INDEX idx_exam_users_country ON exam_users (country);

6. Hash Join  (cost=332.33..1471.21 rows=343 width=25) (actual time=1.626..4.449 rows=1000 loops=1)
  Hash Cond: (o.user_id = u.id)
  Buffers: shared hit=1186 read=3
  ->  Bitmap Heap Scan on exam_orders o  (cost=147.30..1268.02 rows=6915 width=22) (actual time=0.664..2.614 rows=7000 loops=1)
        Recheck Cond: ((created_at >= '2025-03-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-03-08 00:00:00'::timestamp without time zone))
        Heap Blocks: exact=1017
        Buffers: shared hit=1038
        ->  Bitmap Index Scan on idx_exam_orders_created_at  (cost=0.00..145.57 rows=6915 width=0) (actual time=0.490..0.490 rows=7000 loops=1)
              Index Cond: ((created_at >= '2025-03-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-03-08 00:00:00'::timestamp without time zone))
              Buffers: shared hit=21
  ->  Hash  (cost=172.54..172.54 rows=1000 width=11) (actual time=0.949..0.951 rows=1000 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 50kB
        Buffers: shared hit=148 read=3
        ->  Bitmap Heap Scan on exam_users u  (cost=12.04..172.54 rows=1000 width=11) (actual time=0.253..0.742 rows=1000 loops=1)
              Recheck Cond: (country = 'JP'::text)
              Heap Blocks: exact=148
              Buffers: shared hit=148 read=3
              ->  Bitmap Index Scan on idx_exam_users_country  (cost=0.00..11.79 rows=1000 width=0) (actual time=0.176..0.176 rows=1000 loops=1)
                    Index Cond: (country = 'JP'::text)
                    Buffers: shared read=3
Planning:
  Buffers: shared hit=22 read=1
Planning Time: 0.549 ms
Execution Time: 4.524 ms

7. да улучшился, т.к. быстрее поиск по стране

8. shared hit - уже в памяти
   read - читает с диска
```

Задание 3

```text
1. Старая запись пометилась xmax наша транзакция и появилась новая запись с xmin этой же транзакции, ctid у обоих указывает на актуальную 4 по счету запись
2. Для ACID и чтобы старые транзакции могли читать старую запись
3. В xmax поставилась транзакция текущая и теперь запись считается удаленной
4. - Ставит место свободным, но не освобождает место на диске
   - Автоматически когда превышает порог значения делает вакуум
   - Перестраивает хранение на диске, и освобождает место на диске
5. Vacuum full
```

Задание 4

```text
В обоих экспериментах сессия B блокируется и ждет завершения сессии А (везде апдейт)

FOR SHARE блокирует на запись, но разрешает на чтение

FOR UPDATE эксклюзивная блокировка и запрещает все

В дефолт селект нет блокировок, произойдет чтение копии данных

FOR UPDATE для важных данных, где возможен конкуретный доступ
```

Задание 5

```text
CREATE TABLE exam_measurements_src (
    city_id INTEGER NOT NULL,
    log_date DATE NOT NULL,
    peaktemp INTEGER,
    unitsales INTEGER
);

CREATE TABLE exam_measurements (
city_id INTEGER NOT NULL,
log_date DATE NOT NULL,
peaktemp INTEGER,
unitsales INTEGER
) PARTITION BY RANGE (log_date);

CREATE TABLE log_date_jan25 PARTITION OF exam_measurements FOR VALUES FROM ('2025-01-01') TO ('2025-01-31');
CREATE TABLE log_date_feb25 PARTITION OF exam_measurements FOR VALUES FROM ('2025-02-01') TO ('2025-02-28');
CREATE TABLE log_date_mar25 PARTITION OF exam_measurements FOR VALUES FROM ('2025-03-01') TO ('2025-03-31');
CREATE TABLE log_date_def25 PARTITION OF exam_measurements DEFAULT;

Insert into exam_measurements (city_id, log_date, peaktemp, unitsales)
Select city_id, log_date, peaktemp, unitsales
from exam_measurements_src;
```

```text
1.
Seq Scan on exam_measurements_2025_02 exam_measurements  (cost=0.00..25.00 rows=1200 width=12) (actual time=0.015..0.219 rows=1200 loops=1)
Filter: ((log_date >= '2025-02-01'::date) AND (log_date < '2025-03-01'::date))
Buffers: shared hit=7
Planning:
Buffers: shared hit=56
Planning Time: 1.800 ms
Execution Time: 0.300 ms
Append  (cost=0.00..68.62 rows=74 width=12) (actual time=0.016..0.238 rows=74 loops=1)
Buffers: shared hit=22
->  Seq Scan on exam_measurements_2025_01 exam_measurements_1  (cost=0.00..22.00 rows=24 width=12) (actual time=0.015..0.091 rows=24 loops=1)
Filter: (city_id = 10)
Rows Removed by Filter: 1176
Buffers: shared hit=7
->  Seq Scan on exam_measurements_2025_02 exam_measurements_2  (cost=0.00..22.00 rows=24 width=12) (actual time=0.005..0.066 rows=24 loops=1)
Filter: (city_id = 10)
Rows Removed by Filter: 1176
Buffers: shared hit=7
->  Seq Scan on exam_measurements_2025_03 exam_measurements_3  (cost=0.00..22.00 rows=24 width=12) (actual time=0.005..0.067 rows=24 loops=1)
Filter: (city_id = 10)
Rows Removed by Filter: 1176
Buffers: shared hit=7
->  Seq Scan on exam_measurements_default exam_measurements_4  (cost=0.00..2.25 rows=2 width=12) (actual time=0.004..0.007 rows=2 loops=1)
Filter: (city_id = 10)
Rows Removed by Filter: 98
Buffers: shared hit=1
Planning:
Buffers: shared hit=51
Planning Time: 8.277 ms
Execution Time: 0.260 ms

2. Запрос по февралю:
pruning есть, участвует 1 секция
Запрос по city_id = 10:
pruning нет, участвуют все 4 секции
3. pruning работает по ключу секционирования log_date, а не по любому произвольному столбцу
4. Нет, pruning работает из-за того, что предикат запроса сопоставим с ключом секционирования; индекс может помочь уже внутри конкретной секции
5. Для строк вне заданных диапазонов, здесь — для апреля 2025
```
