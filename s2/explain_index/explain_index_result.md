## 1. SELECT item_id FROM marketplace.items WHERE price > 9900;
  Gather  (cost=1000.00..8056.10 rows=3206 width=4) (actual time=0.630..21.468 rows=2954 loops=1)  
  Workers Planned: 2  
  Workers Launched: 2  
  ->  Parallel Seq Scan on items  (cost=0.00..6735.50 rows=1336 width=4) (actual time=0.023..15.603 rows=985 loops=3)  
  Filter: (price > '9900'::numeric)  
  Rows Removed by Filter: 99015  
  Planning Time: 0.319 ms  
  Execution Time: 21.611 ms  
  
  Gather  (cost=1000.00..8056.10 rows=3206 width=4) (actual time=0.278..14.277 rows=2954 loops=1)  
  Workers Planned: 2   
  Workers Launched: 2  
  Buffers: shared hit=3301 read=1872  
  ->  Parallel Seq Scan on items  (cost=0.00..6735.50 rows=1336 width=4) (actual time=0.032..10.023 rows=985 loops=3)  
  Filter: (price > '9900'::numeric)  
  Rows Removed by Filter: 99015  
  Buffers: shared hit=3301 read=1872  
  Planning Time: 0.053 ms  
  Execution Time: 14.408 ms  
  
  ## 2. SELECT order_id FROM marketplace.orders WHERE status = 'delivered';
  
  Seq Scan on orders  (cost=0.00..7636.00 rows=100770 width=4) (actual time=0.010..35.796 rows=100344 loops=1)  
  Filter: ((status)::text = 'delivered'::text)  
  Rows Removed by Filter: 199656  
  Planning Time: 0.207 ms  
  Execution Time: 38.776 ms  
  
  Seq Scan on orders  (cost=0.00..7636.00 rows=100770 width=4) (actual time=0.011..23.040 rows=100344 loops=1)  
  Filter: ((status)::text = 'delivered'::text)  
  Rows Removed by Filter: 199656  
  Buffers: shared hit=3886  
  Planning Time: 0.050 ms  
  Execution Time: 26.302 ms  
  
  ## 3. SELECT purchase_id FROM marketplace.purchases WHERE quantity < 3;  
  
  Seq Scan on purchases  (cost=0.00..10003.00 rows=122293 width=4) (actual time=0.027..65.038 rows=120171 loops=1)  
  Filter: (quantity < 3)  
  Rows Removed by Filter: 279829  
  Planning Time: 0.134 ms  
  Execution Time: 69.334 ms  
  
  Seq Scan on purchases  (cost=0.00..10003.00 rows=122293 width=4) (actual time=0.012..29.259 rows=120171 loops=1)  
  Filter: (quantity < 3)  
  Rows Removed by Filter: 279829  
  Buffers: shared hit=5003  
  Planning Time: 0.046 ms  
  Execution Time: 33.572 ms  
  
  ## 4. SELECT shop_id FROM marketplace.shops WHERE name LIKE 'Shop_1%';
  
  Seq Scan on shops  (cost=0.00..10.25 rows=111 width=4) (actual time=0.009..0.144 rows=111 loops=1)  
  Filter: ((name)::text ~~ 'Shop_1%'::text)  
  Rows Removed by Filter: 389  
  Planning Time: 0.215 ms  
  Execution Time: 0.158 ms  
  
  Seq Scan on shops  (cost=0.00..10.25 rows=111 width=4) (actual time=0.013..0.050 rows=111 loops=1)  
  Filter: ((name)::text ~~ 'Shop_1%'::text)  
  Rows Removed by Filter: 389  
  Buffers: shared hit=4  
  Planning Time: 0.052 ms  
  Execution Time: 0.064 ms  
  
  ## 5. SELECT review_id FROM marketplace.reviews WHERE rating IN (1, 2, 3);
  
  Seq Scan on reviews  (cost=0.00..2111.00 rows=62660 width=4) (actual time=0.008..10.442 rows=62397 loops=1)  
  "  Filter: (rating = ANY ('{1,2,3}'::integer[]))"  
  Rows Removed by Filter: 37603  
  Planning Time: 0.170 ms  
  Execution Time: 12.279 ms  
  
  Seq Scan on reviews  (cost=0.00..2111.00 rows=62660 width=4) (actual time=0.011..7.488 rows=62397 loops=1)  
  "  Filter: (rating = ANY ('{1,2,3}'::integer[]))"  
  Rows Removed by Filter: 37603  
  Buffers: shared hit=736  
  Planning Time: 0.061 ms  
  Execution Time: 9.468 ms  
  
  ## 1. SELECT item_id FROM marketplace.items WHERE price > 9900;  
  
  Bitmap Heap Scan on items  (cost=61.27..4841.30 rows=3206 width=4) (actual time=0.567..1.949 rows=2954 loops=1)  
  Recheck Cond: (price > '9900'::numeric)  
  Heap Blocks: exact=2259  
  ->  Bitmap Index Scan on idx_price_btree  (cost=0.00..60.47 rows=3206 width=0) (actual time=0.303..0.303 rows=2954 loops=1)  
  Index Cond: (price > '9900'::numeric)  
  Planning Time: 0.195 ms  
  Execution Time: 2.047 ms  
  
  Bitmap Heap Scan on items  (cost=61.27..4841.30 rows=3206 width=4) (actual time=0.510..2.089 rows=2954 loops=1)  
  Recheck Cond: (price > '9900'::numeric)  
  Heap Blocks: exact=2259  
  Buffers: shared hit=2270  
  ->  Bitmap Index Scan on idx_price_btree  (cost=0.00..60.47 rows=3206 width=0) (actual time=0.230..0.231 rows=2954 loops=1)  
  Index Cond: (price > '9900'::numeric)  
  Buffers: shared hit=11  
  Planning:  
  Buffers: shared hit=4  
  Planning Time: 0.088 ms  
  Execution Time: 2.198 ms  
  
  Gather  (cost=1000.00..8056.10 rows=3206 width=4) (actual time=0.284..15.284 rows=2954 loops=1)  
  Workers Planned: 2  
  Workers Launched: 2  
  ->  Parallel Seq Scan on items  (cost=0.00..6735.50 rows=1336 width=4) (actual time=0.030..10.377 rows=985 loops=3)  
  Filter: (price > '9900'::numeric)  
  Rows Removed by Filter: 99015  
  Planning Time: 0.159 ms  
  Execution Time: 15.389 ms  
  
  Gather  (cost=1000.00..8056.10 rows=3206 width=4) (actual time=0.235..15.146 rows=2954 loops=1)  
  Workers Planned: 2  
  Workers Launched: 2  
  Buffers: shared hit=3589 read=1584  
  ->  Parallel Seq Scan on items  (cost=0.00..6735.50 rows=1336 width=4) (actual time=0.026..10.936 rows=985 loops=3)  
  Filter: (price > '9900'::numeric)  
  Rows Removed by Filter: 99015  
  Buffers: shared hit=3589 read=1584  
  Planning Time: 0.058 ms  
  Execution Time: 15.323 ms  
  
  ## 2. SELECT order_id FROM marketplace.orders WHERE status = 'delivered';
  
  Bitmap Heap Scan on orders  (cost=1133.39..6279.02 rows=100770 width=4) (actual time=2.332..15.615 rows=100344 loops=1)  
  Recheck Cond: ((status)::text = 'delivered'::text)  
  Heap Blocks: exact=3886  
  ->  Bitmap Index Scan on idx_status_btree  (cost=0.00..1108.20 rows=100770 width=0) (actual time=1.860..1.861 rows=100344 loops=1)  
  Index Cond: ((status)::text = 'delivered'::text)  
  Planning Time: 0.160 ms  
  Execution Time: 18.667 ms  
  
  Bitmap Heap Scan on orders  (cost=1133.39..6279.02 rows=100770 width=4) (actual time=2.315..15.549 rows=100344 loops=1)  
  Recheck Cond: ((status)::text = 'delivered'::text)  
  Heap Blocks: exact=3886  
  Buffers: shared hit=3975  
  ->  Bitmap Index Scan on idx_status_btree  (cost=0.00..1108.20 rows=100770 width=0) (actual time=1.842..1.843 rows=100344 loops=1)  
  Index Cond: ((status)::text = 'delivered'::text)  
  Buffers: shared hit=89  
  Planning Time: 0.058 ms  
  Execution Time: 18.911 ms  
  
  Seq Scan on orders  (cost=0.00..7636.00 rows=100770 width=4) (actual time=0.008..21.561 rows=100344 loops=1)  
  Filter: ((status)::text = 'delivered'::text)  
  Rows Removed by Filter: 199656  
  Planning Time: 0.109 ms  
  Execution Time: 24.245 ms  
  
  Seq Scan on orders  (cost=0.00..7636.00 rows=100770 width=4) (actual time=0.009..22.382 rows=100344 loops=1)  
  Filter: ((status)::text = 'delivered'::text)  
  Rows Removed by Filter: 199656  
  Buffers: shared hit=3886  
  Planning Time: 0.054 ms  
  Execution Time: 25.650 ms  
  
  ## 3. SELECT purchase_id FROM marketplace.purchases WHERE quantity < 3;
  
  Bitmap Heap Scan on purchases  (cost=1368.19..7899.86 rows=122293 width=4) (actual time=2.864..18.689 rows=120171 loops=1)  
  Recheck Cond: (quantity < 3)  
  Heap Blocks: exact=5003  
  ->  Bitmap Index Scan on idx_quantity_btree  (cost=0.00..1337.62 rows=122293 width=0) (actual time=2.243..2.243 rows=120171 loops=1)  
  Index Cond: (quantity < 3)  
  Planning Time: 0.195 ms  
  Execution Time: 22.415 ms  
  
  Bitmap Heap Scan on purchases  (cost=1368.19..7899.86 rows=122293 width=4) (actual time=2.626..19.988 rows=120171 loops=1)  
  Recheck Cond: (quantity < 3)  
  Heap Blocks: exact=5003  
  Buffers: shared hit=5107  
  ->  Bitmap Index Scan on idx_quantity_btree  (cost=0.00..1337.62 rows=122293 width=0) (actual time=2.005..2.006 rows=120171 loops=1)  
  Index Cond: (quantity < 3)  
  Buffers: shared hit=104  
  Planning Time: 0.056 ms  
  Execution Time: 24.039 ms  
  
  Seq Scan on purchases  (cost=0.00..10003.00 rows=122293 width=4) (actual time=0.009..28.893 rows=120171 loops=1)  
  Filter: (quantity < 3)  
  Rows Removed by Filter: 279829  
  Planning Time: 0.101 ms  
  Execution Time: 32.147 ms  
  
  Seq Scan on purchases  (cost=0.00..10003.00 rows=122293 width=4) (actual time=0.013..28.846 rows=120171 loops=1)  
  Filter: (quantity < 3)  
  Rows Removed by Filter: 279829  
  Buffers: shared hit=5003  
  Planning Time: 0.048 ms  
  Execution Time: 32.887 ms  
  
  ## 4. SELECT shop_id FROM marketplace.shops WHERE name LIKE 'Shop_1%';
  
  Seq Scan on shops  (cost=0.00..10.25 rows=111 width=4) (actual time=0.008..0.044 rows=111 loops=1)  
  Filter: ((name)::text ~~ 'Shop_1%'::text)  
  Rows Removed by Filter: 389  
  Planning Time: 0.125 ms  
  Execution Time: 0.056 ms  
  
  Seq Scan on shops  (cost=0.00..10.25 rows=111 width=4) (actual time=0.011..0.049 rows=111 loops=1)  
  Filter: ((name)::text ~~ 'Shop_1%'::text)  
  Rows Removed by Filter: 389  
  Buffers: shared hit=4  
  Planning Time: 0.052 ms  
  Execution Time: 0.062 ms  
  
  Seq Scan on shops  (cost=0.00..10.25 rows=111 width=4) (actual time=0.014..0.061 rows=111 loops=1)  
  Filter: ((name)::text ~~ 'Shop_1%'::text)  
  Rows Removed by Filter: 389  
  Planning Time: 0.176 ms  
  Execution Time: 0.080 ms  
  
  Seq Scan on shops  (cost=0.00..10.25 rows=111 width=4) (actual time=0.013..0.051 rows=111 loops=1)  
  Filter: ((name)::text ~~ 'Shop_1%'::text)  
  Rows Removed by Filter: 389  
  Buffers: shared hit=4  
  Planning Time: 0.061 ms  
  Execution Time: 0.065 ms  
  
  ## 5. SELECT review_id FROM marketplace.reviews WHERE rating IN (1, 2, 3);
  
  Seq Scan on reviews  (cost=0.00..2111.00 rows=62660 width=4) (actual time=0.007..7.329 rows=62397 loops=1)  
  "  Filter: (rating = ANY ('{1,2,3}'::integer[]))"  
  Rows Removed by Filter: 37603  
  Planning Time: 0.128 ms  
  Execution Time: 9.009 ms  
  
  Seq Scan on reviews  (cost=0.00..2111.00 rows=62660 width=4) (actual time=0.009..7.467 rows=62397 loops=1)  
  "  Filter: (rating = ANY ('{1,2,3}'::integer[]))"  
  Rows Removed by Filter: 37603  
  Buffers: shared hit=736  
  Planning Time: 0.065 ms  
  Execution Time: 9.525 ms  
  
  Seq Scan on reviews  (cost=0.00..2111.00 rows=62660 width=4) (actual time=0.007..7.408 rows=62397 loops=1)  
  "  Filter: (rating = ANY ('{1,2,3}'::integer[]))"  
  Rows Removed by Filter: 37603  
  Planning Time: 0.114 ms  
  Execution Time: 9.078 ms  
  
  Seq Scan on reviews  (cost=0.00..2111.00 rows=62660 width=4) (actual time=0.009..7.386 rows=62397 loops=1)  
  "  Filter: (rating = ANY ('{1,2,3}'::integer[]))"  
  Rows Removed by Filter: 37603  
  Buffers: shared hit=736  
  Planning Time: 0.059 ms  
  Execution Time: 9.421 ms  
  