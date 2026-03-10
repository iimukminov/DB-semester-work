
## 1. GIN
### Запрос 1: Поиск по конкретному тегу (высокая селективность)

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT item_id, name
FROM marketplace.items
WHERE tags @> ARRAY['exclusive'];

```

```text
Bitmap Heap Scan on items  (cost=68.90..4990.41 rows=2860 width=15) (actual time=0.583..2.936 rows=2969 loops=1)
  Recheck Cond: (tags @> '{exclusive}'::text[])
  Heap Blocks: exact=2362
  Buffers: shared hit=2365
  ->  Bitmap Index Scan on idx_items_tags  (cost=0.00..68.19 rows=2860 width=0) (actual time=0.309..0.310 rows=2969 loops=1)
        Index Cond: (tags @> '{exclusive}'::text[])
        Buffers: shared hit=3
Planning Time: 0.164 ms
Execution Time: 3.063 ms

```

### Запрос 2: Поиск по частому тегу (низкая селективность)

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT item_id, name
FROM marketplace.items
WHERE tags @> ARRAY['new'];

```

```text
Bitmap Heap Scan on items  (cost=677.55..7796.93 rows=99150 width=15) (actual time=5.652..21.094 rows=100257 loops=1)
  Recheck Cond: (tags @> '{new}'::text[])
  Heap Blocks: exact=5880
  Buffers: shared hit=5897
  ->  Bitmap Index Scan on idx_items_tags  (cost=0.00..652.76 rows=99150 width=0) (actual time=4.948..4.949 rows=100257 loops=1)
        Index Cond: (tags @> '{new}'::text[])
        Buffers: shared hit=17
Planning Time: 0.097 ms
Execution Time: 24.364 ms

```

### Запрос 3: Проверка пересечения массивов (оператор &&)

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT item_id, name
FROM marketplace.items
WHERE tags && ARRAY['exclusive', 'popular'];

```

```text
Bitmap Heap Scan on items  (cost=701.47..7857.53 rows=102085 width=15) (actual time=6.118..21.839 rows=101733 loops=1)
  Recheck Cond: (tags && '{exclusive,popular}'::text[])
  Heap Blocks: exact=5880
  Buffers: shared hit=5899
  ->  Bitmap Index Scan on idx_items_tags  (cost=0.00..675.95 rows=102085 width=0) (actual time=5.386..5.387 rows=101733 loops=1)
        Index Cond: (tags && '{exclusive,popular}'::text[])
        Buffers: shared hit=19
Planning Time: 0.073 ms
Execution Time: 25.152 ms

```

### Запрос 4: Поиск по ключу и значению в JSONB

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT item_id, metadata
FROM marketplace.items
WHERE metadata @> '{"color": "black"}';

```

```text
Bitmap Heap Scan on items  (cost=430.08..7066.89 rows=60545 width=50) (actual time=8.135..29.752 rows=59806 loops=1)
  Recheck Cond: (metadata @> '{"color": "black"}'::jsonb)
  Heap Blocks: exact=5880
  Buffers: shared hit=5961
  ->  Bitmap Index Scan on idx_items_metadata  (cost=0.00..414.94 rows=60545 width=0) (actual time=7.437..7.438 rows=59806 loops=1)
        Index Cond: (metadata @> '{"color": "black"}'::jsonb)
        Buffers: shared hit=81
Planning Time: 0.086 ms
Execution Time: 31.798 ms

```

### Запрос 5: Проверка наличия ключа в JSONB

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT item_id
FROM marketplace.items
WHERE metadata ? 'weight';

```

```text
Seq Scan on items  (cost=0.00..9630.00 rows=299970 width=4) (actual time=0.014..53.352 rows=300000 loops=1)
  Filter: (metadata ? 'weight'::text)
  Buffers: shared hit=5880
Planning Time: 0.094 ms
Execution Time: 63.336 ms

```

## GiST 

### Запрос 1: Пересечение временных диапазонов

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT purchase_id, delivery_window
FROM marketplace.purchases
WHERE delivery_window && tsrange('2026-03-01', '2026-03-07');

```

```text
Index Scan using idx_purchases_window on purchases  (cost=0.28..8.30 rows=1 width=26) (actual time=0.015..0.016 rows=0 loops=1)
  Index Cond: (delivery_window && '["2026-03-01 00:00:00","2026-03-07 00:00:00")'::tsrange)
  Buffers: shared hit=1
Planning Time: 0.100 ms
Execution Time: 0.025 ms

```

### Запрос 2: Вхождение в широкий диапазон (Seq Scan)

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT purchase_id, delivery_window
FROM marketplace.purchases
WHERE delivery_window <@ tsrange('2026-03-01', '2026-04-01');

```

```text
Seq Scan on purchases  (cost=0.00..10003.00 rows=397339 width=26) (actual time=0.027..78.477 rows=400000 loops=1)
  Filter: (delivery_window <@ '["2026-03-01 00:00:00","2026-04-01 00:00:00")'::tsrange)
  Buffers: shared hit=1934 read=3069
Planning Time: 0.072 ms
Execution Time: 91.551 ms

```

### Запрос 3: Проверка вхождения точки времени в диапазон

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT purchase_id, delivery_window
FROM marketplace.purchases
WHERE delivery_window @> '2026-03-10 15:00:00'::timestamp;

```

```text
Seq Scan on purchases  (cost=0.00..10003.00 rows=400000 width=26) (actual time=0.129..72.817 rows=400000 loops=1)
  Filter: (delivery_window @> '2026-03-10 15:00:00'::timestamp without time zone)
  Buffers: shared hit=1966 read=3037
Planning Time: 0.064 ms
Execution Time: 86.600 ms

```

### Запрос 4: Поиск ближайших соседей

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, location
FROM marketplace.orders
ORDER BY location <-> point(50, 50)
LIMIT 5;

```

```text
Limit  (cost=0.28..0.80 rows=5 width=28) (actual time=0.069..0.077 rows=5 loops=1)
  Buffers: shared hit=5 read=4
  ->  Index Scan using idx_orders_location on orders  (cost=0.28..31328.28 rows=300000 width=28) (actual time=0.068..0.075 rows=5 loops=1)
        Order By: (location <-> '(50,50)'::point)
        Buffers: shared hit=5 read=4
Planning Time: 0.352 ms
Execution Time: 0.095 ms

```

### Запрос 5: Поиск точек внутри области

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, location
FROM marketplace.orders
WHERE location <@ box '(40,40),(60,60)';

```

```text
Bitmap Heap Scan on orders  (cost=14.61..937.92 rows=300 width=20) (actual time=1.523..5.442 rows=11741 loops=1)
  Recheck Cond: (location <@ '(60,60),(40,40)'::box)
  Heap Blocks: exact=3687
  Buffers: shared hit=3691 read=101
  ->  Bitmap Index Scan on idx_orders_location  (cost=0.00..14.53 rows=300 width=0) (actual time=1.042..1.043 rows=11741 loops=1)
        Index Cond: (location <@ '(60,60),(40,40)'::box)
        Buffers: shared hit=4 read=101
Planning Time: 0.056 ms
Execution Time: 5.859 ms

```