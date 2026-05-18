CREATE SCHEMA IF NOT EXISTS olap;

-- 1. Измерение: Даты
CREATE TABLE olap.dim_date (
                               date_id INT PRIMARY KEY, -- Формат YYYYMMDD
                               full_date DATE NOT NULL,
                               year INT NOT NULL,
                               month INT NOT NULL,
                               day INT NOT NULL,
                               day_of_week INT NOT NULL
);

-- 2. Измерение: Покупатели
CREATE TABLE olap.dim_buyer (
                                buyer_sk SERIAL PRIMARY KEY,    -- Суррогатный ключ
                                buyer_id INT NOT NULL,          -- Натуральный ключ из OLTP
                                login VARCHAR(255) NOT NULL
);

-- 3. Измерение: Товары (денормализовано: товар + категория + магазин)
CREATE TABLE olap.dim_item (
                               item_sk SERIAL PRIMARY KEY,
                               item_id INT NOT NULL,
                               item_name VARCHAR(255) NOT NULL,
                               category_name VARCHAR(255),
                               shop_name VARCHAR(255),
                               base_price DECIMAL(10, 2)
);

-- 4. Измерение: ПВЗ
CREATE TABLE olap.dim_pvz (
                              pvz_sk SERIAL PRIMARY KEY,
                              pvz_id INT NOT NULL,
                              address VARCHAR(255) NOT NULL
);

-- 5. Таблица фактов: Продажи
CREATE TABLE olap.fact_sales (
                                 fact_id SERIAL PRIMARY KEY,
                                 date_id INT REFERENCES olap.dim_date(date_id),
                                 buyer_sk INT REFERENCES olap.dim_buyer(buyer_sk),
                                 item_sk INT REFERENCES olap.dim_item(item_sk),
                                 pvz_sk INT REFERENCES olap.dim_pvz(pvz_sk), -- Может быть NULL, если заказ еще не оформлен на ПВЗ

    -- Измерения вырожденные (Degenerate dimensions)
                                 purchase_status VARCHAR(50),
                                 order_status VARCHAR(50),

    -- Метрики (Measures)
                                 quantity INT,
                                 discount_percent INT,
                                 total_price DECIMAL(10, 2),
                                 rating INT,
                                 helpful_count INT
);