-- чистим данные и сбрасываем последовательности
TRUNCATE marketplace.reviews,
         marketplace.orders,
         marketplace.purchases,
         marketplace.items,
         marketplace.shops,
         marketplace.pvz,
         marketplace.buyers,
         marketplace.workers,
         marketplace.category_of_item
         RESTART IDENTITY CASCADE;

-- справочники
INSERT INTO marketplace.category_of_item (name, description)
VALUES ('Electronics', 'Gadgets'),
       ('Clothing', 'Apparel'),
       ('Food', 'Groceries'),
       ('Books', 'Literature'),
       ('Sports', 'Equipment'),
       ('Home', 'Furniture'),
       ('Beauty', 'Cosmetics'),
       ('Toys', 'Kids'),
       ('Auto', 'Parts'),
       ('Hobby', 'Crafts');

INSERT INTO marketplace.workers (login, password_hash, salt)
SELECT 'worker_' || gs, md5('pass' || gs), 'salt'
FROM generate_series(1, 500) gs;

INSERT INTO marketplace.buyers (login, password_hash, salt)
SELECT 'buyer_' || gs, md5('pass' || gs), 'salt'
FROM generate_series(1, 1000) gs;

INSERT INTO marketplace.pvz (address)
SELECT 'Address ' || gs
FROM generate_series(1, 300) gs;

INSERT INTO marketplace.shops (owner_id, name)
SELECT gs, 'Shop_' || gs
FROM generate_series(1, 500) gs;

-- 300k: zipf (70% товаров в ТОП-50 магазинах из 500 всего)
INSERT INTO marketplace.items (shop_id, name, description, category_id, price, tags, metadata)
SELECT
    CASE WHEN random() < 0.7 THEN
        (random()*49)::int+1
    ELSE
        (random()*449)::int+51
    END, -- Zipf
    'Item_'||gs,
    'Description '||gs,
    (gs%10)+1,
    (random()*10000)::numeric(10,2),
    ARRAY['tag', 'new'],
    jsonb_build_object('color', 'red')
FROM generate_series(1, 300000) gs;

-- 400k: равномерное (status 3 значения равномерно)
INSERT INTO marketplace.purchases (item_id, buyer_id, purchase_date, status, quantity, total_price, discount_percent, delivery_window)
SELECT
    (random()*299999)::int+1,
    (random()*999)::int+1,
    NOW() - (random()*365)*'1 day'::interval,
    (ARRAY['pending','completed','cancelled'])[ceil(random()*3)], -- Равномерное
    (random()*5)::int+1,
    (random()*5000)::numeric(10,2),
    CASE WHEN random() < 0.2 THEN
        NULL
    ELSE
        (random()*30)::int
    END,
    tsrange(NOW()::timestamp, (NOW()+'7 days'::interval)::timestamp)
FROM generate_series(1, 400000) gs;

-- 300k: низкая селективность (notes: 3 варианта или NULL)
INSERT INTO marketplace.orders (purchase_id, pvz_id, status, order_date, tracking_number, location, notes, delivery_date)
SELECT
    gs,
    (random()*299)::int+1,
    (ARRAY['created','delivered','cancelled'])[ceil(random()*3)],
    NOW() - (random()*30)*'1 day'::interval,
    'TRACK-'||gs,
    point(random()*100, random()*100),
    CASE WHEN random() < 0.7 THEN
        NULL
    ELSE
        (ARRAY['Urgent','Fragile','Gift'])[ceil(random()*3)]
    END, -- Низкая селективность

    CASE WHEN random() < 0.5 THEN
       NOW()
    ELSE
       NULL
    END
FROM generate_series(1, 300000) gs;

-- 100k: высокая селективность (description уникальные)
INSERT INTO marketplace.reviews (purchase_id, rating, description, helpful_count)
SELECT
    gs,
    (random()*4)::int+1,
    'Review '||gs, -- Высокая селективность (~100% уникальных)
    (random()*100)::int
FROM generate_series(1, 100000) gs;
