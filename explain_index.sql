--без 1
EXPLAIN (ANALYZE) SELECT item_id FROM marketplace.items WHERE price > 9900;
EXPLAIN (ANALYZE, BUFFERS) SELECT item_id FROM marketplace.items WHERE price > 9900;

CREATE INDEX idx_price_btree ON marketplace.items (price);
-- бтри 1
EXPLAIN (ANALYZE) SELECT item_id FROM marketplace.items WHERE price > 9900;
EXPLAIN (ANALYZE, BUFFERS) SELECT item_id FROM marketplace.items WHERE price > 9900;

DROP INDEX marketplace.idx_price_btree;

CREATE INDEX idx_price_hash ON marketplace.items USING HASH (price);
--хэш 1
EXPLAIN (ANALYZE) SELECT item_id FROM marketplace.items WHERE price > 9900;
EXPLAIN (ANALYZE, BUFFERS) SELECT item_id FROM marketplace.items WHERE price > 9900;

DROP INDEX marketplace.idx_price_hash;

--без 2
EXPLAIN (ANALYZE) SELECT order_id FROM marketplace.orders WHERE status = 'delivered';
EXPLAIN (ANALYZE, BUFFERS) SELECT order_id FROM marketplace.orders WHERE status = 'delivered';


CREATE INDEX idx_status_btree ON marketplace.orders (status);
--бтри 2
EXPLAIN (ANALYZE) SELECT order_id FROM marketplace.orders WHERE status = 'delivered';
EXPLAIN (ANALYZE, BUFFERS) SELECT order_id FROM marketplace.orders WHERE status = 'delivered';

DROP INDEX marketplace.idx_status_btree;

CREATE INDEX idx_status_hash ON marketplace.orders USING HASH (status);
--хэш 2
EXPLAIN (ANALYZE) SELECT order_id FROM marketplace.orders WHERE status = 'delivered';
EXPLAIN (ANALYZE, BUFFERS) SELECT order_id FROM marketplace.orders WHERE status = 'delivered';

DROP INDEX marketplace.idx_status_hash;

--без 3
EXPLAIN (ANALYZE) SELECT purchase_id FROM marketplace.purchases WHERE quantity < 3;
EXPLAIN (ANALYZE, BUFFERS) SELECT purchase_id FROM marketplace.purchases WHERE quantity < 3;


CREATE INDEX idx_quantity_btree ON marketplace.purchases (quantity);
--бтри 3
EXPLAIN (ANALYZE) SELECT purchase_id FROM marketplace.purchases WHERE quantity < 3;
EXPLAIN (ANALYZE, BUFFERS) SELECT purchase_id FROM marketplace.purchases WHERE quantity < 3;

DROP INDEX marketplace.idx_quantity_btree;


CREATE INDEX idx_quantity_hash ON marketplace.purchases USING HASH (quantity);
--хэш 3
EXPLAIN (ANALYZE) SELECT purchase_id FROM marketplace.purchases WHERE quantity < 3;
EXPLAIN (ANALYZE, BUFFERS) SELECT purchase_id FROM marketplace.purchases WHERE quantity < 3;

DROP INDEX marketplace.idx_quantity_hash;

--без 4
EXPLAIN (ANALYZE) SELECT shop_id FROM marketplace.shops WHERE name LIKE 'Shop_1%';
EXPLAIN (ANALYZE, BUFFERS) SELECT shop_id FROM marketplace.shops WHERE name LIKE 'Shop_1%';


CREATE INDEX idx_shop_name_btree ON marketplace.shops (name);
--бтри 4
EXPLAIN (ANALYZE) SELECT shop_id FROM marketplace.shops WHERE name LIKE 'Shop_1%';
EXPLAIN (ANALYZE, BUFFERS) SELECT shop_id FROM marketplace.shops WHERE name LIKE 'Shop_1%';

DROP INDEX marketplace.idx_shop_name_btree;


CREATE INDEX idx_shop_name_hash ON marketplace.shops USING HASH (name);
--хэш 4
EXPLAIN (ANALYZE) SELECT shop_id FROM marketplace.shops WHERE name LIKE 'Shop_1%';
EXPLAIN (ANALYZE, BUFFERS) SELECT shop_id FROM marketplace.shops WHERE name LIKE 'Shop_1%';

DROP INDEX marketplace.idx_shop_name_hash;

--без 5
EXPLAIN (ANALYZE) SELECT review_id FROM marketplace.reviews WHERE rating IN (1, 2, 3);
EXPLAIN (ANALYZE, BUFFERS) SELECT review_id FROM marketplace.reviews WHERE rating IN (1, 2, 3);


CREATE INDEX idx_rating_btree ON marketplace.reviews (rating);
--бтри 5
EXPLAIN (ANALYZE) SELECT review_id FROM marketplace.reviews WHERE rating IN (1, 2, 3);
EXPLAIN (ANALYZE, BUFFERS) SELECT review_id FROM marketplace.reviews WHERE rating IN (1, 2, 3);

DROP INDEX marketplace.idx_rating_btree;


CREATE INDEX idx_rating_hash ON marketplace.reviews USING HASH (rating);
--хэш 5
EXPLAIN (ANALYZE) SELECT review_id FROM marketplace.reviews WHERE rating IN (1, 2, 3);
EXPLAIN (ANALYZE, BUFFERS) SELECT review_id FROM marketplace.reviews WHERE rating IN (1, 2, 3);

DROP INDEX marketplace.idx_rating_hash;
