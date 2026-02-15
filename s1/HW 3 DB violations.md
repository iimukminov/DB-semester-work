# Нарушения:
## 1НФ (Первой нормальной формы)

```
CREATE TABLE marketplace.workers (
    worker_id SERIAL PRIMARY KEY,
    login VARCHAR(255),
    password VARCHAR(255),
    work_id INT,    -- профессия
    shop_id INT,    -- магазин
    pvz_id INT      -- пункт выдачи
);
```

Место работы "размазывается" на несколько полей

```
-- 9. Таблица назначений работников (решает проблему 1НФ)
CREATE TABLE marketplace.worker_assignments (
    worker_id INT REFERENCES marketplace.workers(worker_id),
    place_type VARCHAR(20) CHECK (
        place_type = 'shop' OR place_type = 'pvz'
    ),
    place_id INT,
    work_id INT REFERENCES marketplace.profession(profession_id)
);
```

## 2 НФ
```
CREATE TABLE marketplace.reviews (
    review_id SERIAL PRIMARY KEY,      -- первичный ключ
    buyer_id INT,                      -- частично зависит от purchase_id!
    purchase_id INT,                   --
    description VARCHAR(255),
    date DATE DEFAULT CURRENT_DATE
);
```

Решение

```
CREATE TABLE marketplace.reviews (
    review_id SERIAL PRIMARY KEY,
    purchase_id INT NOT NULL UNIQUE REFERENCES marketplace.purchases(purchase_id),
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    description TEXT
);
```

## 3 НФ

```
CREATE TABLE marketplace.profession (
    profession_id SERIAL PRIMARY KEY,  -- первичный ключ
    name VARCHAR(255),
    salary INT,
    promotion_id INT REFERENCES marketplace.profession(profession_id)
);
```

Проблема: Циклическая транзитивная зависимость

Решение:

```
CREATE TABLE marketplace.career_path (
    path_id SERIAL PRIMARY KEY,
    current_profession_id INT NOT NULL REFERENCES marketplace.profession(profession_id),
    next_profession_id INT NOT NULL REFERENCES marketplace.profession(profession_id)
);
```