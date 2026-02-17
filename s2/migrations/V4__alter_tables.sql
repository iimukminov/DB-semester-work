-- добавление полей, чтобы удовлетворять условию
ALTER TABLE marketplace.items
    ADD COLUMN IF NOT EXISTS tags TEXT[],            -- Массивы
    ADD COLUMN IF NOT EXISTS metadata JSONB;         -- JSONB

ALTER TABLE marketplace.purchases
    ADD COLUMN IF NOT EXISTS delivery_window TSRANGE,      -- Range-тип
    ADD COLUMN IF NOT EXISTS discount_percent INT,         -- NULL-поля
    ADD COLUMN IF NOT EXISTS total_price DECIMAL(10,2),    -- Диапазонные
    ADD COLUMN IF NOT EXISTS quantity INT DEFAULT 1;       -- Диапазонные

ALTER TABLE marketplace.orders
    ADD COLUMN IF NOT EXISTS location POINT,               -- Геометрический тип
    ADD COLUMN IF NOT EXISTS tracking_number VARCHAR(100), -- Высокая кардинальность
    ADD COLUMN IF NOT EXISTS notes TEXT,                   -- Полнотекстовые
    ADD COLUMN IF NOT EXISTS delivery_date TIMESTAMP;      -- NULL-поля

-- доп. поле чтобы было 5 полей
ALTER TABLE marketplace.reviews
    ADD COLUMN IF NOT EXISTS helpful_count INT DEFAULT 0;
