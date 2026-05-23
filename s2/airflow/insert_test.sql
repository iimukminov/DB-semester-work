-- 1. Создаем тестового покупателя (идемпотентно)
INSERT INTO marketplace.buyers (login, password_hash, salt)
VALUES ('test_buyer_01', 'hash123', 'salt123')
    ON CONFLICT (login) DO NOTHING;

-- 2. Оформляем покупку (автоматически берем 1-й товар из API и нашего покупателя)
INSERT INTO marketplace.purchases (item_id, buyer_id, quantity, total_price, status)
SELECT
    (SELECT item_id FROM marketplace.items LIMIT 1),
    (SELECT buyer_id FROM marketplace.buyers WHERE login = 'test_buyer_01' LIMIT 1),
    2,
    (SELECT price * 2 FROM marketplace.items LIMIT 1),
    'completed';

-- 3. Привязываем покупку к ПВЗ (автоматически берем 1-й ПВЗ из CSV)
INSERT INTO marketplace.orders (purchase_id, pvz_id, status)
SELECT
    (SELECT purchase_id FROM marketplace.purchases ORDER BY purchase_id DESC LIMIT 1),
    (SELECT pvz_id FROM marketplace.pvz LIMIT 1),
    'delivered'
ON CONFLICT (purchase_id) DO NOTHING;