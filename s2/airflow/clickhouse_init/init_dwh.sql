-- Создаем широкую таблицу фактов
CREATE TABLE IF NOT EXISTS default.fact_sales_wide (
                                                       purchase_id UInt32,
                                                       purchase_date DateTime,
                                                       item_name String,
                                                       category_name String,
                                                       shop_name String,
                                                       pvz_address String,
                                                       quantity UInt16,
                                                       total_price Float32,
                                                       status String
) ENGINE = ReplacingMergeTree()
    ORDER BY (purchase_date, purchase_id);

-- Создаем аналитическую витрину (Materialized View)
CREATE MATERIALIZED VIEW IF NOT EXISTS default.mart_daily_revenue
ENGINE = SummingMergeTree()
ORDER BY (date, category_name)
AS SELECT
              toDate(purchase_date) AS date,
    category_name,
    sum(total_price) AS daily_revenue,
    sum(quantity) AS items_sold
   FROM default.fact_sales_wide
   WHERE status = 'completed'
   GROUP BY date, category_name;