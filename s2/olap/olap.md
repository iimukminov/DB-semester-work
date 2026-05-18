### 1. Цель работы и бизнес-требования

1. **Какая динамика продаж (выручка и количество) по дням в разрезе категорий товаров?** (Помогает понять сезонность и популярность категорий).
2. **Какие магазины (shops) приносят наибольшую выручку и при этом имеют самый высокий средний рейтинг?** (Поиск лучших селлеров площадки).
3. **Какая конверсия заказов (от создания до доставки) в разрезе пунктов выдачи (ПВЗ)?** (Оценка качества логистики и работы ПВЗ).

### 2. Архитектура аналитического хранилища (Модель данных)

Для реализации аналитического хранилища выбрана классическая денормализованная модель **«Звезда» (Star Schema)**. Она позволяет минимизировать количество операций `JOIN` при чтении и оптимизирована для агрегаций.

* **Главный факт:** `fact_sales` (Факты продаж).
* **Зерно факта (Гранулярность):** 1 строка = 1 транзакция покупки (`purchase`).
  *Обоснование:* В исходной OLTP-модели соблюдается отношение 1 к 1 (или 1 к 0) между сущностями `purchase`, `order` и `review`. Это позволяет консолидировать все ключевые метрики (цена, скидка, статус доставки, оценка пользователя) в рамках одной строки таблицы фактов, избегая избыточного дублирования фактов.
* **Измерения (Dimensions):** Спроектировано 4 измерения.
* `dim_date` (Календарное измерение времени).
* `dim_buyer` (Измерение покупателя).
* `dim_item` (Денормализованное измерение товара, включающее в себя атрибуты категории и магазина).
* `dim_pvz` (Измерение пунктов выдачи).


* **Суррогатные ключи:** Во всех таблицах измерений внедрены суррогатные ключи (`_sk`), сгенерированные последовательностью (`SERIAL`). Это обеспечивает независимость DWH от первичных ключей исходной системы и закладывает основу для реализации историчности

### 3. DDL: Инициализация схемы OLAP

Ниже представлены скрипты создания структуры хранилища:

```sql
CREATE SCHEMA IF NOT EXISTS olap;

-- 1. Измерение: Даты (Calendar Dimension)
CREATE TABLE olap.dim_date (
    date_id INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT NOT NULL,
    month INT NOT NULL,
    day INT NOT NULL,
    day_of_week INT NOT NULL
);

-- 2. Измерение: Покупатели
CREATE TABLE olap.dim_buyer (
    buyer_sk SERIAL PRIMARY KEY,
    buyer_id INT NOT NULL,
    login VARCHAR(255) NOT NULL
);

-- 3. Измерение: Товары (Денормализовано: Товар + Категория + Магазин)
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
    pvz_sk INT REFERENCES olap.dim_pvz(pvz_sk),
    
    -- Вырожденные измерения (Degenerate dimensions)
    purchase_status VARCHAR(50),
    order_status VARCHAR(50),
    
    -- Метрики (Measures)
    quantity INT,
    discount_percent INT,
    total_price DECIMAL(10, 2),
    rating INT,
    helpful_count INT
);

```

### 4. ETL-процесс: Миграция данных

Для переноса данных из `marketplace` в `olap` разработаны скрипты, выполняющие извлечение, трансформацию и загрузку.

*Особенности логики загрузки:* При наполнении таблицы фактов применяется `LEFT JOIN` к таблицам `orders` и `reviews`. Это гарантирует сохранение записей о покупках даже в том случае, если заказ на ПВЗ еще не сформирован или пользователь не оставил отзыв. Метрика `total_price` рассчитывается динамически с использованием функции `COALESCE` для обработки отсутствующих значений.

```sql
-- 4.1. Генерация календарного измерения
INSERT INTO olap.dim_date (date_id, full_date, year, month, day, day_of_week)
SELECT 
    TO_CHAR(d, 'YYYYMMDD')::INT,
    d,
    EXTRACT(YEAR FROM d),
    EXTRACT(MONTH FROM d),
    EXTRACT(DAY FROM d),
    EXTRACT(ISODOW FROM d)
FROM generate_series('2023-01-01'::DATE, '2026-12-31'::DATE, '1 day'::interval) d;

-- 4.2. Наполнение измерения покупателей
INSERT INTO olap.dim_buyer (buyer_id, login)
SELECT buyer_id, login FROM marketplace.buyers;

-- 4.3. Наполнение измерения товаров (со слиянием справочников)
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

-- 4.4. Наполнение измерения ПВЗ
INSERT INTO olap.dim_pvz (pvz_id, address)
SELECT pvz_id, address FROM marketplace.pvz;

-- 4.5. Построение таблицы фактов (сопоставление суррогатных ключей)
INSERT INTO olap.fact_sales (
    date_id, buyer_sk, item_sk, pvz_sk, 
    purchase_status, order_status, quantity, discount_percent, total_price, rating, helpful_count
)
SELECT 
    TO_CHAR(p.purchase_date, 'YYYYMMDD')::INT AS date_id,
    db.buyer_sk,
    di.item_sk,
    dp.pvz_sk, 
    p.status AS purchase_status,
    o.status AS order_status,
    p.quantity,
    p.discount_percent,
    COALESCE(p.total_price, (p.quantity * di.base_price * (1 - COALESCE(p.discount_percent, 0) / 100.0))),
    r.rating,
    r.helpful_count
FROM marketplace.purchases p
LEFT JOIN marketplace.orders o ON p.purchase_id = o.purchase_id
LEFT JOIN marketplace.reviews r ON p.purchase_id = r.purchase_id
JOIN olap.dim_buyer db ON p.buyer_id = db.buyer_id
JOIN olap.dim_item di ON p.item_id = di.item_id
LEFT JOIN olap.dim_pvz dp ON o.pvz_id = dp.pvz_id;

```

### 5. Аналитические SQL-запросы

Благодаря внедрению схемы «Звезда», выполнение бизнес-запросов требует минимального количества соединений таблиц, что значительно снижает нагрузку на СУБД по сравнению с запросами к 3НФ OLTP-схеме.

**Запрос 1: Динамика продаж по дням и категориям**

```sql
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
```


| full\_date | category\_name | total\_revenue | total\_items\_sold |
| :--- | :--- | :--- | :--- |
| 2026-05-18 | Toys | 94346.82 | 145 |
| 2026-05-18 | Food | 90274.27 | 172 |
| 2026-05-18 | Clothing | 84322.8 | 122 |
| 2026-05-18 | Electronics | 82776.88 | 136 |
| 2026-05-18 | Books | 81310.65 | 114 |
| 2026-05-18 | Auto | 75398.7 | 102 |
| 2026-05-18 | Sports | 67451.34 | 116 |
| 2026-05-18 | Home | 65011.38 | 91 |
| 2026-05-18 | Beauty | 60946.17 | 93 |
| 2026-05-18 | Hobby | 55107.6 | 79 |
| 2026-05-17 | Sports | 115923.22 | 159 |
| 2026-05-17 | Hobby | 107882.77 | 111 |
| 2026-05-17 | Books | 94117.43 | 140 |
| 2026-05-17 | Auto | 89421.9 | 117 |
| 2026-05-17 | Electronics | 89052.89 | 145 |
| 2026-05-17 | Home | 84317.45 | 129 |
| 2026-05-17 | Toys | 74572.71 | 98 |
| 2026-05-17 | Beauty | 66840.21 | 131 |
| 2026-05-17 | Food | 60356 | 95 |
| 2026-05-17 | Clothing | 51414.81 | 66 |
| 2026-05-16 | Beauty | 115923.67 | 164 |


**Запрос 2: Топ-10 магазинов по выручке со средним рейтингом**

```sql
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
```

| shop\_name | sales\_count | total\_revenue | avg\_rating |
| :--- | :--- | :--- | :--- |
| Shop\_29 | 1982 | 5047217.49 | 3.02 |
| Shop\_34 | 1987 | 4965150.97 | 3.02 |
| Shop\_49 | 1948 | 4944721.19 | 2.97 |
| Shop\_14 | 1983 | 4942167.37 | 2.98 |
| Shop\_21 | 1948 | 4934553.19 | 2.92 |
| Shop\_47 | 1920 | 4924218.99 | 2.97 |
| Shop\_15 | 1940 | 4911065.43 | 3.03 |
| Shop\_36 | 1983 | 4906881.17 | 3.06 |
| Shop\_10 | 1963 | 4899564.56 | 3.04 |
| Shop\_6 | 1984 | 4895516.56 | 3.08 |


**Запрос 3: Воронка логистики (Конверсия заказов по ПВЗ)**

```sql
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
```

| pvz\_address | total\_orders | delivered\_count | cancelled\_count | delivery\_conversion\_percent |
| :--- | :--- | :--- | :--- | :--- |
| Address 169 | 1099 | 385 | 606 | 35.03 |
| Address 24 | 1082 | 372 | 579 | 34.38 |
| Address 149 | 1079 | 375 | 596 | 34.75 |
| Address 261 | 1076 | 366 | 584 | 34.01 |
| Address 205 | 1074 | 343 | 588 | 31.94 |
| Address 138 | 1072 | 357 | 594 | 33.3 |
| Address 173 | 1071 | 349 | 601 | 32.59 |
| Address 276 | 1069 | 345 | 607 | 32.27 |
| Address 55 | 1067 | 339 | 581 | 31.77 |
| Address 236 | 1066 | 359 | 559 | 33.68 |
| Address 217 | 1062 | 342 | 599 | 32.2 |
| Address 98 | 1060 | 370 | 589 | 34.91 |
| Address 9 | 1059 | 348 | 561 | 32.86 |
| Address 123 | 1056 | 347 | 571 | 32.86 |
| Address 294 | 1056 | 353 | 564 | 33.43 |
| Address 298 | 1052 | 347 | 597 | 32.98 |
| Address 151 | 1052 | 356 | 563 | 33.84 |
| Address 69 | 1052 | 379 | 570 | 36.03 |
| Address 132 | 1051 | 344 | 595 | 32.73 |
| Address 237 | 1050 | 357 | 587 | 34 |
| Address 231 | 1049 | 367 | 578 | 34.99 |
