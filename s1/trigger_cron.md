## NEW

### 1. При создании покупателя приводим логин к нижнему регистру
```sql
CREATE OR REPLACE FUNCTION marketplace.adjust_login_format() RETURNS trigger AS $$
BEGIN
	NEW.login := TRIM(LOWER(NEW.login));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_buyer_login
BEFORE INSERT ON marketplace.buyers
FOR EACH ROW
EXECUTE FUNCTION marketplace.adjust_login_format();
```
```sql
INSERT INTO marketplace.buyers (login, password_hash, salt)
VALUES ('UserLogin123', 'hash', 'saltvalue'); 
```
<img width="616" height="34" alt="изображение" src="https://github.com/user-attachments/assets/4bd36b2a-caf2-41cd-a219-787440ccebad" />

### 2. Нормализация логина работника

```sql
-- Триггерная функция
CREATE OR REPLACE FUNCTION marketplace.normalize_worker_login()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.login := TRIM(LOWER(NEW.login));
    RETURN NEW;
END;
$$;

-- триггер
CREATE TRIGGER worker_normalize_login
BEFORE INSERT OR UPDATE ON marketplace.workers
FOR EACH ROW
EXECUTE FUNCTION marketplace.normalize_worker_login();
```

Проверка:

```sql
INSERT INTO marketplace.workers (login, password_hash, salt)
VALUES ('  NewWorker  ', 'hash_test', 'salt_test');
```
<img width="747" height="141" alt="Скриншот 02-12-2025 195855" src="https://github.com/user-attachments/assets/2a637880-dce4-45d6-9ebb-35738dad7e80" />

## OLD

### 1. При обновлении товара новая цена не должна быть больше старой в 5 и более раз
```sql
CREATE OR REPLACE FUNCTION marketplace.validate_item_price() RETURNS trigger AS $$
BEGIN
	IF (NEW.price >= OLD.price * 5) THEN
		RAISE EXCEPTION 'Подозрительный скачок цены';
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_update_items
BEFORE UPDATE ON marketplace.items
FOR EACH ROW
EXECUTE FUNCTION marketplace.validate_item_price();
```
```sql
INSERT INTO marketplace.items (shop_id, name, category_id, price) VALUES (1, 'TestItem', 1, 100);
```
```sql
UPDATE marketplace.items SET price = 600 WHERE name = 'TestItem'; 
```
<img width="667" height="143" alt="изображение" src="https://github.com/user-attachments/assets/c858534a-50d2-42f4-b5d9-9c99a594ed10" />   
<img width="497" height="32" alt="изображение" src="https://github.com/user-attachments/assets/af1be9ec-31d7-40d1-a25b-330dd1fe487c" />

### 2. Удаление отзыва при отмене покупки

```sql
-- Триггерная функция
CREATE OR REPLACE FUNCTION marketplace.delete_review_on_cancel()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.status = 'completed' AND NEW.status = 'cancelled' THEN
        DELETE FROM marketplace.reviews
        WHERE purchase_id = OLD.purchase_id;
        
        RAISE NOTICE 'Отзыв для покупки % был удалён из-за отмены', OLD.purchase_id;
    END IF;
    
    RETURN NEW;
END;
$$;

-- триггер
CREATE TRIGGER purchase_cancel_remove_review
AFTER UPDATE ON marketplace.purchases
FOR EACH ROW
EXECUTE FUNCTION marketplace.delete_review_on_cancel();
```

Проверка:
<img width="1052" height="148" alt="Скриншот 02-12-2025 200137" src="https://github.com/user-attachments/assets/8e3465c8-11a9-47b2-9b2d-987359488e08" />
```sql
UPDATE marketplace.purchases SET status = 'cancelled' WHERE purchase_id = 1;
```
<img width="1077" height="151" alt="Скриншот 02-12-2025 200211" src="https://github.com/user-attachments/assets/6160f0c2-0db9-4da1-8d89-53180b259f72" />




## BEFORE

### 1. Перед добавлением отзыва (reviews), проверяю, что связанная покупка (purchases) имеет статус completed. Если статус pending или cancelled, то кидаю ошибку
```sql
CREATE OR REPLACE FUNCTION marketplace.check_purchase_status() RETURNS trigger AS $$
DECLARE
	purchase_status VARCHAR;
BEGIN
	SELECT p.status INTO purchase_status
	FROM marketplace.purchases p
	WHERE p.purchase_id = NEW.purchase_id;

	IF purchase_status IS NULL THEN
		RAISE EXCEPTION 'Нет покупки с таким id';
	ELSIF purchase_status != 'completed' THEN
		RAISE EXCEPTION 'Нельзя оставить отзыв для невыполненной покупки';
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_review
BEFORE INSERT ON marketplace.reviews
FOR EACH ROW
EXECUTE FUNCTION marketplace.check_purchase_status();
```
```sql
-- Попытка вставить отзыв для покупки с не 'completed' статусом
INSERT INTO marketplace.reviews (purchase_id, rating, description)
VALUES (42, 1, 'Пушка бомба петарда, просто огонь, мне понравилось. Но у меня плохое настроение поэтому 1'); 
```
<img width="698" height="159" alt="изображение" src="https://github.com/user-attachments/assets/53cda83f-71a1-4ec3-8439-18de18a0bb61" />

### 2. Нормализация рейтинга

```sql
-- Триггерная функция
CREATE OR REPLACE FUNCTION marketplace.normalize_review_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.rating < 1 THEN
        NEW.rating := 1;
        RAISE NOTICE 'Рейтинг был изменён с % на 1 (минимальное значение)', NEW.rating;
    END IF;
    
    IF NEW.rating > 5 THEN
        NEW.rating := 5;
        RAISE NOTICE 'Рейтинг был изменён c % на 5 (максимальное значение)',
NEW.rating;
    END IF;
    
    RETURN NEW;
END;
$$;

-- триггер
CREATE TRIGGER review_normalize_rating
BEFORE INSERT OR UPDATE ON marketplace.reviews
FOR EACH ROW
EXECUTE FUNCTION marketplace.normalize_review_rating();
```

Проверка:

```sql
INSERT INTO marketplace.reviews (purchase_id, rating, description)
VALUES (4, 10, 'Слишком высокий рейтинг');
```
<img width="1071" height="151" alt="Скриншот 02-12-2025 200314" src="https://github.com/user-attachments/assets/43bdc641-71a3-4bc0-b4ee-c5423ac133a7" />


## AFTER

### 1. После вставки записи в purchases, если цена купленного товара больше 50 000, вывести сообщение в консоль о крупной покупке
```sql
CREATE OR REPLACE FUNCTION marketplace.check_big_price_item_purchase() RETURNS trigger AS $$
DECLARE
	big_price DECIMAL(10,2);
BEGIN
	SELECT i.price INTO big_price
	FROM marketplace.items i
	WHERE i.item_id = NEW.item_id;

	IF big_price > 50000 THEN
		RAISE NOTICE 'Внимание! Крупная покупка: ID %, Сумма %', NEW.purchase_id, big_price;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_insert_purchase_check_price
AFTER INSERT ON marketplace.purchases
FOR EACH ROW
EXECUTE FUNCTION marketplace.check_big_price_item_purchase();
```
```sql
INSERT INTO marketplace.purchases (item_id, buyer_id) VALUES (1, 1); 
```
<img width="468" height="148" alt="изображение" src="https://github.com/user-attachments/assets/7010be2d-7862-4d2f-9ee7-19e87f4b7253" />

### 2. После добавления нового карьерного пути показать работников, которые на него претендуют

```sql
CREATE OR REPLACE FUNCTION marketplace.get_workers_to_promote()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
	worker_logins TEXT;
	worker_record RECORD;
BEGIN
	worker_logins := '';
    
    FOR worker_record IN 
        SELECT w.login
        FROM marketplace.workers w
        JOIN marketplace.worker_assignments wa ON wa.worker_id = w.worker_id
        WHERE wa.work_id = NEW.current_profession_id
    LOOP
        worker_logins := worker_logins || worker_record.login || ', ';
    END LOOP;
	
	RAISE NOTICE 'Работники для повышения с профессии % на %: %', 
        NEW.current_profession_id, 
        NEW.next_profession_id,
        worker_logins;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER after_insert_new_promotion_get_workers
AFTER INSERT ON marketplace.career_path 
FOR EACH ROW
EXECUTE FUNCTION marketplace.get_workers_to_promote();
```

```sql
INSERT INTO marketplace.career_path(current_profession_id, next_profession_id) VALUES (1, 11);
```

<img width="718" height="115" alt="image" src="https://github.com/user-attachments/assets/7bffdb6c-2eef-4ea1-958d-5b18e5fe8eb4" />


## ROW level

### 1. Для каждой строки items: если поле description пустое/null, то заполняю его именем товара
```sql
CREATE OR REPLACE FUNCTION marketplace.remove_empty_item_description() RETURNS trigger AS $$
BEGIN
	IF NEW.description IS NULL or NEW.description = '' THEN
		NEW.description := NEW.name;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_update_items
BEFORE INSERT OR UPDATE ON marketplace.items
FOR EACH ROW
EXECUTE FUNCTION marketplace.remove_empty_item_description();
```
```sql
INSERT INTO marketplace.items (shop_id, name, category_id, price, description)
VALUES (1, 'NoDescriptionItem', 1, 100, NULL);
```
<img width="877" height="133" alt="изображение" src="https://github.com/user-attachments/assets/997c32b1-1886-4b72-a3a9-7c2cd3c7ecc3" />

### 2. Для каждой строки, добавленной в career path проверить не резкое ли повышение

```sql
create or replace function marketplace.throw_bad_promotion()
returns trigger
language plpgsql
AS $$
DECLARE
	cur_sal INT;
	next_sal INT;
BEGIN
	SELECT salary INTO cur_sal FROM marketplace.profession p WHERE p.profession_id = NEW.current_profession_id;
	SELECT salary INTO next_sal FROM marketplace.profession p WHERE p.profession_id = NEW.next_profession_id;
	IF cur_sal * 2 < next_sal THEN
		RAISE NOTICE 'Повышение зарплаты с должности с id % на должность с id % с зарплатами %,% соответсвенно слишком резкое',
		NEW.current_profession_id, NEW.next_profession_id, cur_sal, next_sal;
	END IF;
	return NEW;
END;
$$;

CREATE Trigger get_bad_promotions
AFTER INSERT ON marketplace.career_path 
FOR EACH ROW
EXECUTE FUNCTION marketplace.throw_bad_promotion();
```

```sql
INSERT INTO marketplace.career_path(current_profession_id, next_profession_id) VALUES (1, 3);
```

<img width="1292" height="135" alt="image" src="https://github.com/user-attachments/assets/416eb4fe-a0df-42e3-8065-6116132d7fc9" />


## STATEMENT level

### 1. При попытке очистить таблицу полностью(TRUNCATE), выбросить ошибку
```sql
CREATE OR REPLACE FUNCTION marketplace.cancel_truncate_buyers() RETURNS trigger AS $$
BEGIN
	RAISE EXCEPTION 'Очистка базы покупателей запрещена';
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_truncate_buyers
BEFORE TRUNCATE ON marketplace.buyers
FOR EACH STATEMENT
EXECUTE FUNCTION marketplace.cancel_truncate_buyers();
```
```sql
TRUNCATE TABLE marketplace.buyers CASCADE;
```
<img width="685" height="115" alt="изображение" src="https://github.com/user-attachments/assets/659e43c8-9d8f-40e4-bb1f-7002f3026df3" />

### 2. Нельзя удалять товары перед парой бд

```sql
create or replace function marketplace.check_delete()
returns trigger
language plpgsql
AS $$
BEGIN
	IF CURRENT_DATE = '2025-12-02' THEN
            RAISE EXCEPTION 'Нельзя удалять товары перед сдачей бд';
    END IF;
    RETURN NEW;
END;
$$;

create or replace trigger check_delete_items
BEFORE delete on marketplace.items
FOR EACH STATEMENT
EXECUTE FUNCTION marketplace.check_delete();
```

```sql
DELETE FROM marketplace.items i WHERE i.item_id = 57;
```

<img width="859" height="164" alt="image" src="https://github.com/user-attachments/assets/e16000af-6512-4ab5-af92-00aa9e3b64cc" />


## CRON

### 1. Каждую ночь в 04:00. Он должен переводить в статус cancelled все заказы из таблицы marketplace.orders, которые находятся в статусе created уже более 10 дней.
```sql
SELECT cron.schedule(
  'cancel_old_created_orders',
  '0 4 * * *',
  $$ UPDATE marketplace.orders o
  SET o.status = 'cancelled' 
  WHERE o.status = 'created' AND o.order_date < NOW() - interval '10 days';
  $$
);
```
![Без имени](https://github.com/user-attachments/assets/db6c47ef-a6e0-4f09-b07e-04056bf161be)   
<img width="1418" height="112" alt="изображение" src="https://github.com/user-attachments/assets/7b0ca783-9e98-4e01-89ec-31274eb2e042" />   

<img width="2079" height="35" alt="изображение" src="https://github.com/user-attachments/assets/5b09f6ef-80be-4235-bc4a-38b015c4022c" />   

<img width="616" height="38" alt="изображение" src="https://github.com/user-attachments/assets/f91295ae-b317-4926-a7c2-81978901496e" />

### 2. Удаление отзывов для отменённых покупок раз в сутки

```sql
SELECT cron.schedule(
    'cleanup_cancelled_reviews',
    '0 4 * * *',
    $$
    DELETE FROM marketplace.reviews r
    USING marketplace.purchases p
    WHERE r.purchase_id = p.purchase_id
      AND p.status = 'cancelled';
    $$
);
```
<img width="802" height="214" alt="Скриншот 02-12-2025 195613" src="https://github.com/user-attachments/assets/09745f79-ba2b-4e73-8fc2-3eac6eb30234" />
<img width="731" height="221" alt="Скриншот 02-12-2025 195750" src="https://github.com/user-attachments/assets/883d474b-f3f7-4b0e-8501-19ce36b545b1" />

### 3. Повышение цен на товары каждый месяц (для запроса поменяли на каждую минуту)
```sql
SELECT cron.schedule(
    'monthly_price_increase',
    '0 9 1 * *',
    $$
    UPDATE marketplace.items 
    SET price = price * 1.01
    WHERE price < 10000;
    $$
);
```

<img width="1429" height="109" alt="image_2025-12-02_23-31-33" src="https://github.com/user-attachments/assets/cc6efbf7-3289-45cb-997b-ea1ee2ed3ce6" />
<img width="2111" height="153" alt="image_2025-12-02_23-32-16" src="https://github.com/user-attachments/assets/9f35ab6c-5bba-4c0e-94f5-649cc75b54cd" />


***
Список триггеров: 
```sql
select * from information_schema.triggers;
```
<img width="2334" height="176" alt="Скриншот 02-12-2025 195822" src="https://github.com/user-attachments/assets/a6767f93-c593-40ca-b4de-df80853c3f3f" />

Список cron:
```sql
select * from cron.job;
```
<img width="1419" height="172" alt="Скриншот 02-12-2025 195714" src="https://github.com/user-attachments/assets/7f67a812-78ac-43a3-b0ae-8f51991a9792" />

запрос на просмотр выполнения кронов

```sql
select * from cron.job_run_details;
```
<img width="1683" height="595" alt="image_2025-12-02_23-19-36" src="https://github.com/user-attachments/assets/07e19fa1-b266-40b6-9dd1-494eb0a1a750" />
