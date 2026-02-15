```sql
-- Очистка таблиц и сброс последовательностей
TRUNCATE TABLE marketplace.reviews RESTART IDENTITY CASCADE;
TRUNCATE TABLE marketplace.orders RESTART IDENTITY CASCADE;
TRUNCATE TABLE marketplace.purchases RESTART IDENTITY CASCADE;
TRUNCATE TABLE marketplace.worker_assignments RESTART IDENTITY CASCADE;
TRUNCATE TABLE marketplace.items RESTART IDENTITY CASCADE;
TRUNCATE TABLE marketplace.shops RESTART IDENTITY CASCADE;
TRUNCATE TABLE marketplace.pvz RESTART IDENTITY CASCADE;
TRUNCATE TABLE marketplace.buyers RESTART IDENTITY CASCADE;
TRUNCATE TABLE marketplace.workers RESTART IDENTITY CASCADE;
TRUNCATE TABLE marketplace.career_path RESTART IDENTITY CASCADE;
TRUNCATE TABLE marketplace.profession RESTART IDENTITY CASCADE;
TRUNCATE TABLE marketplace.category_of_item RESTART IDENTITY CASCADE;
```
независимые данные
```sql
INSERT INTO marketplace.profession (name, salary) VALUES
('Программист', 120000),
('Дизайнер', 90000),
('Менеджер', 100000),
('Тестировщик', 85000);

INSERT INTO marketplace.category_of_item (name, description) VALUES
('Электроника', 'Техника и гаджеты'),
('Книги', 'Печатная продукция'),
('Одежда', 'Вещи для гардероба'),
('Еда', 'Продукты питания');

INSERT INTO marketplace.pvz (address) VALUES
('ул. Ленина, 10'),
('ул. Гагарина, 20'),
('пр. Победы, 3'),
('ул. Пушкина, 13');

INSERT INTO marketplace.workers (login, password_hash, salt) VALUES
('ivanov', 'hash1', 'salt1'),
('petrov', 'hash2', 'salt2'),
('sidorov', 'hash3', 'salt3'),
('smirnov', 'hash4', 'salt4');

INSERT INTO marketplace.buyers (login, password_hash, salt) VALUES
('alex', 'hash5', 'salt5'),
('elena', 'hash6', 'salt6'),
('anton', 'hash7', 'salt7'),
('maria', 'hash8', 'salt8');

INSERT INTO marketplace.career_path (current_profession_id, next_profession_id) VALUES
(1, 2),
(2, 3),
(3, 4),
(4, 1);
```

Зависимые данные
```sql
INSERT INTO marketplace.shops (owner_id, name) VALUES
(1, 'Магазин электроники'),
(2, 'Книжный магазин'),
(3, 'Магазин одежды'),
(4, 'Супермаркет');

INSERT INTO marketplace.items (shop_id, name, description, category_id, price) VALUES
(1, 'Ноутбук', 'Мощный ноутбук', 1, 50000.00),
(2, 'Книга Java', 'Учебник по Java', 2, 1200.00),
(3, 'Футболка', 'Стильная футболка', 3, 890.00),
(4, 'Сыр', 'Рокфор 200г', 4, 370.00),
(1, 'Смартфон', 'Бюджетный', 1, 15000),
(1, 'Планшет', '10 дюймов', 1, 25000),
(2, 'Книга Python', 'Учебник', 2, 800),
(3, 'Джинсы', 'Синие', 3, 2000);

INSERT INTO marketplace.worker_assignments (worker_id, place_type, place_id, work_id) VALUES
(1, 'shop', 1, 1),
(2, 'shop', 2, 2),
(3, 'pvz', 1, 3),
(4, 'pvz', 2, 4);

INSERT INTO marketplace.purchases (item_id, buyer_id, purchase_date, status) VALUES
(1, 1, NOW() - INTERVAL '5 days', 'completed'),
(2, 2, NOW() - INTERVAL '4 days', 'completed'),
(3, 3, NOW() - INTERVAL '3 days', 'completed'),
(4, 4, NOW() - INTERVAL '2 days', 'completed'),
(5, 1, NOW() - INTERVAL '1 day', 'completed'),
(6, 2, NOW(), 'completed'),
(7, 3, NOW(), 'completed'),
(8, 4, NOW(), 'completed');

INSERT INTO marketplace.orders (purchase_id, pvz_id, status, order_date) VALUES
(1, 1, 'delivered', NOW() - INTERVAL '5 days'),
(2, 2, 'delivered', NOW() - INTERVAL '4 days'),
(3, 3, 'delivered', NOW() - INTERVAL '3 days'),
(4, 4, 'delivered', NOW() - INTERVAL '2 days'),
(5, 1, 'created', NOW() - INTERVAL '1 day'),
(6, 2, 'created', NOW()),
(7, 3, 'created', NOW()),
(8, 4, 'created', NOW());

INSERT INTO marketplace.reviews (purchase_id, rating, description) VALUES
(1, 5, 'Отлично все понравилось'),
(2, 4, 'Хороший товар'),
(3, 2, 'Плохая упаковка'),
(4, 3, 'Средне, ожидал большего'),
(5, 5, 'Супре!!!!'),
(6, 4, 'Норм'),
(7, 2, 'Bad'),
(8, 5, 'Отличное качество');
```