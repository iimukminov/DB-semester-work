--Gin
CREATE INDEX idx_items_tags ON marketplace.items USING GIN (tags);
CREATE INDEX idx_items_metadata ON marketplace.items USING GIN (metadata jsonb_ops);

EXPLAIN (ANALYZE, BUFFERS)
SELECT item_id, name
FROM marketplace.items
WHERE tags @> ARRAY['exclusive'];

EXPLAIN (ANALYZE, BUFFERS)
SELECT item_id, name
FROM marketplace.items
WHERE tags @> ARRAY['new'];

EXPLAIN (ANALYZE, BUFFERS)
SELECT item_id, name
FROM marketplace.items
WHERE tags && ARRAY['exclusive', 'popular'];

EXPLAIN (ANALYZE, BUFFERS)
SELECT item_id, metadata
FROM marketplace.items
WHERE metadata @> '{"color": "black"}';

EXPLAIN (ANALYZE, BUFFERS)
SELECT item_id
FROM marketplace.items
WHERE metadata ? 'weight';

DROP INDEX IF EXISTS marketplace.idx_items_tags;
DROP INDEX IF EXISTS marketplace.idx_items_metadata;


-- Gist
CREATE INDEX idx_purchases_window ON marketplace.purchases USING GIST (delivery_window);
CREATE INDEX idx_orders_location ON marketplace.orders USING GIST (location);

EXPLAIN (ANALYZE, BUFFERS)
SELECT purchase_id, delivery_window
FROM marketplace.purchases
WHERE delivery_window && tsrange('2026-03-01', '2026-03-07');

EXPLAIN (ANALYZE, BUFFERS)
SELECT purchase_id, delivery_window
FROM marketplace.purchases
WHERE delivery_window <@ tsrange('2026-03-01', '2026-04-01');

EXPLAIN (ANALYZE, BUFFERS)
SELECT purchase_id, delivery_window
FROM marketplace.purchases
WHERE delivery_window @> '2026-03-10 15:00:00'::timestamp;

EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, location
FROM marketplace.orders
ORDER BY location <-> point(50, 50)
LIMIT 5;

EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, location
FROM marketplace.orders
WHERE location <@ box '(40,40),(60,60)';

DROP INDEX IF EXISTS marketplace.idx_purchases_window;
DROP INDEX IF EXISTS marketplace.idx_orders_location;