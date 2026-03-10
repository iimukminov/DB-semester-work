CREATE INDEX idx_items_shop_id ON marketplace.items(shop_id);
CREATE INDEX idx_purchases_item_id ON marketplace.purchases(item_id);
CREATE INDEX idx_purchases_buyer_id ON marketplace.purchases(buyer_id);

-- 1. Nested Loop Join
EXPLAIN ANALYZE
SELECT s.name AS shop_name, i.name AS item_name
FROM marketplace.shops s
         JOIN marketplace.items i ON s.shop_id = i.shop_id
WHERE s.shop_id = 42;

-- 2. Hash Join
EXPLAIN ANALYZE
SELECT i.name, p.status
FROM marketplace.items i
         JOIN marketplace.purchases p ON i.item_id = p.item_id
WHERE i.price > 8000;

-- 3. Merge Join
EXPLAIN ANALYZE
SELECT b.login, p.purchase_date
FROM marketplace.buyers b
         JOIN marketplace.purchases p ON b.buyer_id = p.buyer_id
ORDER BY b.buyer_id;

-- 4. Множественный JOIN
EXPLAIN ANALYZE
SELECT b.login, o.tracking_number
FROM marketplace.buyers b
         JOIN marketplace.purchases p ON b.buyer_id = p.buyer_id
         JOIN marketplace.orders o ON p.purchase_id = o.purchase_id
WHERE b.buyer_id < 50;

-- 5. LEFT JOIN
EXPLAIN ANALYZE
SELECT c.name
FROM marketplace.category_of_item c
         LEFT JOIN marketplace.items i ON c.category_id = i.category_id
WHERE i.item_id IS NULL;

DROP INDEX IF EXISTS marketplace.idx_items_shop_id;
DROP INDEX IF EXISTS marketplace.idx_purchases_item_id;
DROP INDEX IF EXISTS marketplace.idx_purchases_buyer_id;