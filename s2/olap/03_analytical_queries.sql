-- Запрос 1: Динамика продаж по дням и категориям

SELECT
    d.full_date,
    i.category_name,
    SUM(f.total_price) AS total_revenue,
    SUM(f.quantity) AS total_items_sold
FROM olap.fact_sales f
JOIN olap.dim_date d ON f.date_id = d.date_id
JOIN olap.dim_item i ON f.item_sk = i.item_sk
WHERE f.purchase_status = 'completed'
GROUP BY d.full_date, i.category_name
ORDER BY d.full_date DESC, total_revenue DESC;


-- Запрос 2: Топ-10 магазинов по выручке со средним рейтингом

SELECT
    i.shop_name,
    COUNT(f.fact_id) AS sales_count,
    SUM(f.total_price) AS total_revenue,
    ROUND(AVG(f.rating), 2) AS avg_rating
FROM olap.fact_sales f
JOIN olap.dim_item i ON f.item_sk = i.item_sk
WHERE f.purchase_status = 'completed'
GROUP BY i.shop_name
ORDER BY total_revenue DESC
LIMIT 10;



-- Запрос 3: Воронка логистики (Конверсия заказов по ПВЗ)

SELECT
    p.address AS pvz_address,
    COUNT(f.fact_id) AS total_orders,
    SUM(CASE WHEN f.order_status = 'delivered' THEN 1 ELSE 0 END) AS delivered_count,
    SUM(CASE WHEN f.order_status = 'cancelled' OR f.purchase_status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_count,
    ROUND(
        SUM(CASE WHEN f.order_status = 'delivered' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(f.fact_id), 0), 2
    ) AS delivery_conversion_percent
FROM olap.fact_sales f
JOIN olap.dim_pvz p ON f.pvz_sk = p.pvz_sk
WHERE f.pvz_sk IS NOT NULL
GROUP BY p.address
ORDER BY total_orders DESC;


