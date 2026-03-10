## 1. Nested Loop Join


```sql
EXPLAIN ANALYZE
SELECT s.name AS shop_name, i.name AS item_name
FROM marketplace.shops s
         JOIN marketplace.items i ON s.shop_id = i.shop_id
WHERE s.shop_id = 42;

```

```text
Nested Loop  (cost=48.00..5723.84 rows=4040 width=19) (actual time=2.816..6.220 rows=4248 loops=1)
  ->  Index Scan using shops_pkey on shops s  (cost=0.27..8.29 rows=1 width=12) (actual time=0.937..0.941 rows=1 loops=1)
        Index Cond: (shop_id = 42)
  ->  Bitmap Heap Scan on items i  (cost=47.73..5675.15 rows=4040 width=15) (actual time=1.814..4.859 rows=4248 loops=1)
        Recheck Cond: (shop_id = 42)
        Heap Blocks: exact=3041
        ->  Bitmap Index Scan on idx_items_shop_id  (cost=0.00..46.72 rows=4040 width=0) (actual time=1.329..1.329 rows=4248 loops=1)
              Index Cond: (shop_id = 42)
Planning Time: 1.874 ms
Execution Time: 6.410 ms

```


## 2. Hash Join

```sql
EXPLAIN ANALYZE
SELECT i.name, p.status
FROM marketplace.items i
         JOIN marketplace.purchases p ON i.item_id = p.item_id
WHERE i.price > 8000;

```

```text
Hash Join  (cost=10388.89..20441.90 rows=80948 width=20) (actual time=42.100..146.782 rows=80850 loops=1)
  Hash Cond: (p.item_id = i.item_id)
  ->  Seq Scan on purchases p  (cost=0.00..9003.00 rows=400000 width=13) (actual time=0.045..35.146 rows=400000 loops=1)
  ->  Hash  (cost=9630.00..9630.00 rows=60711 width=15) (actual time=41.997..41.999 rows=60629 loops=1)
        Buckets: 65536  Batches: 1  Memory Usage: 3354kB
        ->  Seq Scan on items i  (cost=0.00..9630.00 rows=60711 width=15) (actual time=0.006..31.700 rows=60629 loops=1)
              Filter: (price > '8000'::numeric)
              Rows Removed by Filter: 239371
Planning Time: 2.918 ms
Execution Time: 149.154 ms

```


## 3. Merge Join

```sql
EXPLAIN ANALYZE
SELECT b.login, p.purchase_date
FROM marketplace.buyers b
         JOIN marketplace.purchases p ON b.buyer_id = p.buyer_id
ORDER BY b.buyer_id;

```

```text
Merge Join  (cost=0.70..32455.41 rows=400000 width=21) (actual time=0.050..357.925 rows=400000 loops=1)
  Merge Cond: (b.buyer_id = p.buyer_id)
  ->  Index Scan using buyers_pkey on buyers b  (cost=0.28..49.27 rows=1000 width=13) (actual time=0.008..0.871 rows=1000 loops=1)
  ->  Index Scan using idx_purchases_buyer_id on purchases p  (cost=0.42..27403.63 rows=400000 width=12) (actual time=0.039..319.374 rows=400000 loops=1)
Planning Time: 3.514 ms
Execution Time: 373.455 ms

```


## 4. Множественный JOIN


```sql
EXPLAIN ANALYZE
SELECT b.login, o.tracking_number
FROM marketplace.buyers b
         JOIN marketplace.purchases p ON b.buyer_id = p.buyer_id
         JOIN marketplace.orders o ON p.purchase_id = o.purchase_id
WHERE b.buyer_id < 50;

```

```text
Gather  (cost=1010.17..13567.00 rows=14700 width=21) (actual time=0.686..114.398 rows=14429 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Nested Loop  (cost=10.17..11097.00 rows=6125 width=21) (actual time=0.175..106.276 rows=4810 loops=3)
    ->  Hash Join  (cost=9.75..7118.77 rows=8167 width=13) (actual time=0.117..24.809 rows=6411 loops=3)
          Hash Cond: (p.buyer_id = b.buyer_id)
          ->  Parallel Seq Scan on purchases p  (cost=0.00..6669.67 rows=166667 width=8) (actual time=0.011..14.767 rows=133333 loops=3)
          ->  Hash  (cost=9.13..9.13 rows=49 width=13) (actual time=0.035..0.036 rows=49 loops=3)
                ->  Index Scan using buyers_pkey on buyers b  (cost=0.28..9.13 rows=49 width=13) (actual time=0.016..0.022 rows=49 loops=3)
                      Index Cond: (buyer_id < 50)
    ->  Index Scan using orders_purchase_id_key on orders o  (cost=0.42..0.49 rows=1 width=16) (actual time=0.012..0.012 rows=1 loops=19233)
          Index Cond: (purchase_id = p.purchase_id)
Planning Time: 3.621 ms
Execution Time: 115.192 ms

```

## 5. LEFT JOIN 

```sql
EXPLAIN ANALYZE
SELECT c.name
FROM marketplace.category_of_item c
         LEFT JOIN marketplace.items i ON c.category_id = i.category_id
WHERE i.item_id IS NULL;

```

```text
Hash Right Join  (cost=13.15..9704.49 rows=1 width=516) (actual time=46.371..46.375 rows=0 loops=1)
  Hash Cond: (i.category_id = c.category_id)
  Filter: (i.item_id IS NULL)
  Rows Removed by Filter: 300000
  ->  Seq Scan on items i  (cost=0.00..8880.00 rows=300000 width=8) (actual time=0.010..16.212 rows=300000 loops=1)
  ->  Hash  (cost=11.40..11.40 rows=140 width=520) (actual time=0.343..0.345 rows=10 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 9kB
        ->  Seq Scan on category_of_item c  (cost=0.00..11.40 rows=140 width=520) (actual time=0.334..0.336 rows=10 loops=1)
Planning Time: 0.827 ms
Execution Time: 46.408 ms
```