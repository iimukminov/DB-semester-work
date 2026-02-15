```
-- Удаляем старую схему если существует
DROP SCHEMA IF EXISTS marketplace CASCADE;
CREATE SCHEMA marketplace;

-- 1. Таблица профессий (убрали циклическую ссылку)
CREATE TABLE marketplace.profession (
    profession_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    salary INT NOT NULL CHECK (salary > 0)
);

-- 2. Таблица карьерного роста (отдельно от профессий)
CREATE TABLE marketplace.career_path (
    path_id SERIAL PRIMARY KEY,
    current_profession_id INT NOT NULL REFERENCES marketplace.profession(profession_id),
    next_profession_id INT NOT NULL REFERENCES marketplace.profession(profession_id)
);

-- 3. Таблица работников
CREATE TABLE marketplace.workers (
    worker_id SERIAL PRIMARY KEY,
    login VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(50) NOT NULL
);

-- 4. Таблица покупателей
CREATE TABLE marketplace.buyers (
    buyer_id SERIAL PRIMARY KEY,
    login VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(50) NOT NULL
);

-- 5. Таблица ПВЗ (пунктов выдачи заказов)
CREATE TABLE marketplace.pvz (
    pvz_id SERIAL PRIMARY KEY,
    address VARCHAR(255) NOT NULL UNIQUE
);

-- 6. Таблица магазинов
CREATE TABLE marketplace.shops (
    shop_id SERIAL PRIMARY KEY,
    owner_id INT REFERENCES marketplace.workers(worker_id),
    name VARCHAR(255) NOT NULL UNIQUE
);

-- 7. Таблица категорий товаров
CREATE TABLE marketplace.category_of_item (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT
);

-- 8. Таблица товаров
CREATE TABLE marketplace.items (
    item_id SERIAL PRIMARY KEY,
    shop_id INT NOT NULL REFERENCES marketplace.shops(shop_id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id INT NOT NULL REFERENCES marketplace.category_of_item(category_id),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0)
);

-- 9. Таблица назначений работников (решает проблему 1НФ)
CREATE TABLE marketplace.worker_assignments (
    worker_id INT REFERENCES marketplace.workers(worker_id),
    place_type VARCHAR(20) CHECK (
        place_type = 'shop' OR place_type = 'pvz'
    ),
    place_id INT,
    work_id INT REFERENCES marketplace.profession(profession_id)
);

-- 10. Таблица покупок
CREATE TABLE marketplace.purchases (
    purchase_id SERIAL PRIMARY KEY,
    item_id INT NOT NULL REFERENCES marketplace.items(item_id),
    buyer_id INT NOT NULL REFERENCES marketplace.buyers(buyer_id),
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'cancelled'))
);

-- 11. Таблица заказов
CREATE TABLE marketplace.orders (
    order_id SERIAL PRIMARY KEY,
    purchase_id INT NOT NULL UNIQUE REFERENCES marketplace.purchases(purchase_id),
    pvz_id INT NOT NULL REFERENCES marketplace.pvz(pvz_id),
    status VARCHAR(50) NOT NULL DEFAULT 'created' CHECK (status IN ('created', 'delivered', 'cancelled')),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. Таблица отзывов (убрали лишние зависимости)
CREATE TABLE marketplace.reviews (
    review_id SERIAL PRIMARY KEY,
    purchase_id INT NOT NULL UNIQUE REFERENCES marketplace.purchases(purchase_id),
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    description TEXT
);
```