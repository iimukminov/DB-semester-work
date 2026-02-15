
CREATE SCHEMA marketplace;  
  
CREATE TABLE marketplace.workers (  
	 worker_id SERIAL PRIMARY KEY,  
	 login VARCHAR(255),  
	 password VARCHAR(255),  
	 work_id INT,  
	 shop_id INT,  
	 pvz_id INT  
);  

CREATE TABLE marketplace.shops (  
	   shop_id SERIAL PRIMARY KEY,  
	   owner_id INT REFERENCES marketplace.workers(worker_id),  
	   name VARCHAR(255)  
);  

CREATE TABLE marketplace.pvz (  
	 pvz_id SERIAL PRIMARY KEY,  
	 address VARCHAR(255)  
);  

CREATE TABLE marketplace.profession (  
	profession_id SERIAL PRIMARY KEY,  
	name VARCHAR(255),  
	salary INT,  
	promotion_id INT REFERENCES marketplace.profession(profession_id)  
);  

CREATE TABLE marketplace.category_of_item (  
	  category_id SERIAL PRIMARY KEY,  
	  name VARCHAR(255)  
);  

CREATE TABLE marketplace.items (  
	   item_id SERIAL PRIMARY KEY,  
	   shop_id INT REFERENCES marketplace.shops(shop_id),  
	   name VARCHAR(255),  
	   description VARCHAR(255),  
	   category_id INT REFERENCES marketplace.category_of_item(category_id)  
);  

CREATE TABLE marketplace.item_category (  
	   item_id     INT NOT NULL REFERENCES marketplace.items(item_id) ON DELETE CASCADE,  
	   category_id INT NOT NULL REFERENCES marketplace.category_of_item(category_id) ON DELETE CASCADE,  
	   PRIMARY KEY (item_id, category_id)  
);  


CREATE TABLE marketplace.buyers (  
	buyer_id SERIAL PRIMARY KEY,  
	login VARCHAR(255),  
	password VARCHAR(255)  
);  

CREATE TABLE marketplace.purchases (  
	   purchase_id SERIAL PRIMARY KEY,  
	   item_id INT REFERENCES marketplace.items(item_id),  
	   buyer_id INT REFERENCES marketplace.buyers(buyer_id),  
	   date DATE DEFAULT CURRENT_DATE  
);  

CREATE TABLE marketplace.orders (  
	order_id SERIAL PRIMARY KEY,  
	pvz_id INT REFERENCES marketplace.pvz(pvz_id),  
	item_id INT REFERENCES marketplace.items(item_id),  
	buyer_id INT REFERENCES marketplace.buyers(buyer_id),  
	status VARCHAR(255)  
);  

CREATE TABLE marketplace.reviews (  
	 review_id SERIAL PRIMARY KEY,  
	 buyer_id INT REFERENCES marketplace.buyers(buyer_id),  
	 purchase_id INT REFERENCES marketplace.purchases(purchase_id),  
	 description VARCHAR(255),  
	 date DATE DEFAULT CURRENT_DATE  
);  
  
-- внешние ключи для таблицы workers после создания всех таблиц  
ALTER TABLE marketplace.workers  
    ADD CONSTRAINT fk_workers_work_id FOREIGN KEY (work_id) REFERENCES marketplace.profession(profession_id),  
    ADD CONSTRAINT fk_workers_shop_id FOREIGN KEY (shop_id) REFERENCES marketplace.shops(shop_id),  
    ADD CONSTRAINT fk_workers_pvz_id FOREIGN KEY (pvz_id) REFERENCES marketplace.pvz(pvz_id);

	
-- настройка внешних ключей других таблиц  
ALTER TABLE marketplace.shops    
    ADD CONSTRAINT uq_shops_owner_id UNIQUE (owner_id);
	
ALTER TABLE marketplace.reviews  
    ADD CONSTRAINT uq_reviews_purchase_id UNIQUE (purchase_id);
	
ALTER TABLE marketplace.profession   
    ADD CONSTRAINT uq_profession_promotion_id UNIQUE (purchase_id);  
  
## Inserts

- INSERT INTO marketplace.workers (login, password, work_id, shop_id, pvz_id) VALUES ('sanya','qwerty1',1,NULL,1);
- INSERT INTO marketplace.workers (login, password, work_id, shop_id, pvz_id) VALUES ('ivan','guldota2',2,NULL,2);
- INSERT INTO marketplace.workers (login, password, work_id, shop_id, pvz_id) VALUES ('olga','zxcshadowfiend3',3,NULL,3);

- INSERT INTO marketplace.shops (owner_id, name) VALUES (1,'Tech Store');
- INSERT INTO marketplace.shops (owner_id, name) VALUES (3,'Fashion Hub');
- INSERT INTO marketplace.shops (owner_id, name) VALUES (5,'Food Market');

- INSERT INTO marketplace.pvz (address) VALUES ('Moscow, Tverskaya 1');
- INSERT INTO marketplace.pvz (address) VALUES ('Kazan, Kremlevskaya 35');
- INSERT INTO marketplace.pvz (address) VALUES ('SPb, Nevsky 100');

- INSERT INTO marketplace.profession (name, salary, promotion_id) VALUES ('Курьер', 30000, NULL);
- INSERT INTO marketplace.profession (name, salary, promotion_id) VALUES ('Сотрудник ПВЗ', 35000, NULL);
- INSERT INTO marketplace.profession (name, salary, promotion_id) VALUES ('Хобби Хорсер', 60000, NULL);

- INSERT INTO marketplace.category_of_item (name) VALUES ('Electronics');
- INSERT INTO marketplace.category_of_item (name) VALUES ('Fruits');
- INSERT INTO marketplace.category_of_item (name) VALUES ('Books');

- INSERT INTO marketplace.items (shop_id, name, description) VALUES (1, 'USB-C Cable 1m', 'Fast charge cable');
- INSERT INTO marketplace.items (shop_id, name, description) VALUES (1, 'Gaming Mouse', 'RGB, 6 buttons');
- INSERT INTO marketplace.items (shop_id, name, description) VALUES (1, 'Mechanical Keyboard', 'Brown switches');
- 
- INSERT INTO marketplace.buyers (login, password) VALUES ('ivan_petrov', 'pass123')
- INSERT INTO marketplace.buyers (login, password) VALUES ('maria_ivanova', 'qwerty');
- INSERT INTO marketplace.buyers (login, password) VALUES ('leha_smirnov', 'admin12345');

- INSERT INTO marketplace.purchases (item_id, buyer_id) VALUES (1, 1);
- INSERT INTO marketplace.purchases (item_id, buyer_id) VALUES (2, 2);
- INSERT INTO marketplace.purchases (item_id, buyer_id) VALUES (3, 3);

- INSERT INTO marketplace.orders (pvz_id, item_id, buyer_id, status) VALUES (1, 1, 1, 'created');
- INSERT INTO marketplace.orders (pvz_id, item_id, buyer_id, status) VALUES (1, 2, 2, 'shipped');
- INSERT INTO marketplace.orders (pvz_id, item_id, buyer_id, status) VALUES (2, 3, 3, 'delivered');

- INSERT INTO marketplace.reviews (buyer_id, purchase_id, description) VALUES (1, 1, 'Отличный кабель, заряжает быстро');
- INSERT INTO marketplace.reviews (buyer_id, purchase_id, description) VALUES (2, 2, 'Удобная мышь, яркая подсветка');
- INSERT INTO marketplace.reviews (buyer_id, purchase_id, description) VALUES (3, 3, 'Клавиатура супер, тактильно приятная');
## Updates

- UPDATE marketplace.orders SET status = 'in_transit' WHERE order_id = 2;
- UPDATE marketplace.items SET description = 'RGB, 6 buttons, 12K DPI' WHERE item_id = 2;
- UPDATE marketplace.profession SET name = initcap(name);
## Alters

- ALTER TABLE marketplace.workers ADD CONSTRAINT uq_worker_login UNIQUE (login);
- ALTER TABLE marketplace.buyers ADD CONSTRAINT uq_buyer_login UNIQUE (login);
- ALTER TABLE marketplace.workers RENAME COLUMN work_id TO profession_id;
- ALTER TABLE marketplace.shops ADD CONSTRAINT uq_shops_name UNIQUE (name)
