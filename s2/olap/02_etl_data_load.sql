-- 1. Заполняем dim_date (генерируем даты на пару лет)
INSERT INTO olap.dim_date (date_id, full_date, year, month, day, day_of_week)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT,
    d,
    EXTRACT(YEAR FROM d),
    EXTRACT(MONTH FROM d),
    EXTRACT(DAY FROM d),
    EXTRACT(ISODOW FROM d)
FROM generate_series('2023-01-01'::DATE, '2026-12-31'::DATE, '1 day'::interval) d;

-- 2. Заполняем dim_buyer
INSERT INTO olap.dim_buyer (buyer_id, login)
SELECT buyer_id, login FROM marketplace.buyers;

-- 3. Заполняем dim_item (Денормализация: джоиним категории и магазины)
INSERT INTO olap.dim_item (item_id, item_name, category_name, shop_name, base_price)
SELECT
    i.item_id,
    i.name,
    c.name,
    s.name,
    i.price
FROM marketplace.items i
         JOIN marketplace.category_of_item c ON i.category_id = c.category_id
         JOIN marketplace.shops s ON i.shop_id = s.shop_id;

-- 4. Заполняем dim_pvz
INSERT INTO olap.dim_pvz (pvz_id, address)
SELECT pvz_id, address FROM marketplace.pvz;

-- 5. Заполняем fact_sales
INSERT INTO olap.fact_sales (
    date_id, buyer_sk, item_sk, pvz_sk,
    purchase_status, order_status, quantity, discount_percent, total_price, rating, helpful_count
)
SELECT
    TO_CHAR(p.purchase_date, 'YYYYMMDD')::INT AS date_id,
    db.buyer_sk,
    di.item_sk,
    dp.pvz_sk, -- LEFT JOIN оставит NULL, если ПВЗ не назначен
    p.status AS purchase_status,
    o.status AS order_status,
    p.quantity,
    p.discount_percent,
    -- Если total_price пустой, высчитываем его из цены, количества и скидки
    COALESCE(p.total_price, (p.quantity * di.base_price * (1 - COALESCE(p.discount_percent, 0) / 100.0))),
    r.rating,
    r.helpful_count
FROM marketplace.purchases p
         LEFT JOIN marketplace.orders o ON p.purchase_id = o.purchase_id
         LEFT JOIN marketplace.reviews r ON p.purchase_id = r.purchase_id
-- Подтягиваем суррогатные ключи
         JOIN olap.dim_buyer db ON p.buyer_id = db.buyer_id
         JOIN olap.dim_item di ON p.item_id = di.item_id
         LEFT JOIN olap.dim_pvz dp ON o.pvz_id = dp.pvz_id;