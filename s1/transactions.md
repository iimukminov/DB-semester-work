# Базовые операции с транзакциями
## Набор 1: new worker → new shop (owner = new worker)

### 1.1. `BEGIN ... COMMIT`: 

```sql
BEGIN;  
  
-- 1) Создаём нового worker  
WITH new_worker as (  
    INSERT INTO marketplace.workers (login, password_hash, salt)  
        VALUES ('new_worker', 'hash_w', 'salt_w')  
        RETURNING worker_id)  
  
-- 2) Создаём новый shop, owner_id = только что созданный worker  
INSERT INTO marketplace.shops (owner_id, name)  
SELECT new_worker.worker_id, 'Новый магазин'  
FROM new_worker  
RETURNING shop_id;  
  
COMMIT;
```
Результат: Новый работник и магазин с владельцем - этим работником успешно создались
<img width="757" height="132" alt="image" src="https://github.com/user-attachments/assets/4d7c01f1-aea8-4d28-9534-8f44d16ac771" />
<img width="615" height="129" alt="image" src="https://github.com/user-attachments/assets/4a4b6d6c-b22b-4efe-9f8d-ed8ea60826e1" />

### 1.2. Та же логика, но с `ROLLBACK`

```sql
BEGIN;  
  
-- 1) Создаём нового worker  
WITH new_worker as (  
    INSERT INTO marketplace.workers (login, password_hash, salt)  
        VALUES ('new_worker', 'hash_w', 'salt_w')  
        RETURNING worker_id)  
  
-- 2) Создаём новый shop, owner_id = только что созданный worker  
INSERT INTO marketplace.shops (owner_id, name)  
SELECT new_worker.worker_id, 'Новый магазин'  
FROM new_worker  
RETURNING shop_id;  
  
ROLLBACK;
```
Результат: запросы транзакции откатились, ничего в таблице не поменялось
<img width="757" height="111" alt="image" src="https://github.com/user-attachments/assets/0799d77f-682a-453c-9018-13a15ede8377" />
<img width="598" height="110" alt="image" src="https://github.com/user-attachments/assets/f947a027-54c0-41fa-ac74-00a1864b7ff1" />

### 1.3. Транзакция с ошибкой (деление на 0)

```sql
BEGIN;  
  
-- 1) Создаём нового worker с ошибкой: деление на 0 в логине  
WITH new_worker as (  
    INSERT INTO marketplace.workers (login, password_hash, salt)  
        VALUES (1/0, 'hash_w', 'salt_w')  
        RETURNING worker_id),  
  
-- 2) Создаём новый shop, owner_id = только что созданный worker  
    new_shop as (INSERT INTO marketplace.shops (owner_id, name)  
    SELECT new_worker.worker_id, 'Новый магазин'  
    FROM new_worker  
    RETURNING shop_id)  
  
-- Эта команда уже не выполнится, транзакция в состоянии aborted  
UPDATE marketplace.shops  
SET name = 'Переименованный магазин'  
FROM  new_shop  
WHERE shops.shop_id = new_shop.shop_id;  
  
COMMIT;
```
Результат: запросы транзакции откатились, ничего в таблице не поменялось
<img width="757" height="111" alt="image" src="https://github.com/user-attachments/assets/6c087f7d-7933-4826-87a2-42793f389491" />
<img width="598" height="110" alt="image" src="https://github.com/user-attachments/assets/717565e9-d86f-4dad-9bf8-bb08062045a6" />

***
## Набор 2: new profession → добавление в career_path для уже существующей

### 2.1. `BEGIN ... COMMIT`: создаём profession и добавляем в career_path

```sql
BEGIN;  
  
-- 1) Создаём новую профессию  
WITH new_profession as (  
    INSERT INTO marketplace.profession (name, salary)  
        VALUES ('Мега разработчик 3000', 420000)  
        RETURNING profession_id)  
  
-- 2) Добавляем запись в career_path:  
INSERT INTO marketplace.career_path (current_profession_id, next_profession_id)  
SELECT 4, new_profession.profession_id  
FROM new_profession;  
  
COMMIT;
```
Результат: Новая профессия и карьерный рост до нее от старой профессии успешно создались
<img width="811" height="113" alt="image" src="https://github.com/user-attachments/assets/7fd0a891-aebc-41e5-8821-d67298d57838" />
<img width="793" height="133" alt="yes car path" src="https://github.com/user-attachments/assets/224fc2ab-e2c1-45c7-b483-4da5fe58184a" />

### 2.2. Та же логика, но с `ROLLBACK`

```sql
BEGIN;  
  
-- 1) Создаём новую профессию  
WITH new_profession as (  
    INSERT INTO marketplace.profession (name, salary)  
        VALUES ('Мега разработчик 3000', 420000)  
        RETURNING profession_id)  
  
-- 2) Добавляем запись в career_path:  
INSERT INTO marketplace.career_path (current_profession_id, next_profession_id)  
SELECT 4, new_profession.profession_id  
FROM new_profession;  
  
ROLLBACK;
```
Результат: запросы транзакции откатились, ничего в таблице не поменялось
<img width="809" height="97" alt="image" src="https://github.com/user-attachments/assets/47f65862-9313-44ab-bb01-9e7d32b89bf5" />
<img width="797" height="109" alt="no car path" src="https://github.com/user-attachments/assets/98b62217-30c9-4621-8b07-58add20dc552" />

### 2.3. Транзакция с ошибкой

```sql
BEGIN;  
  
-- 1) Создаём новую профессию  
WITH new_profession as (  
    INSERT INTO marketplace.profession (name, salary)  
        VALUES ('Мега разработчик 3000', 420000)  
        RETURNING profession_id)  
  
-- 2) Добавляем запись в career_path:  
INSERT INTO marketplace.career_path (current_profession_id, next_profession_id)  
SELECT 4, new_profession.profession_id  
FROM new_profession;  
  
-- 3) Намеренная ошибка  
SELECT 1 / 0;  
  
-- Эта команда уже не выполнится, транзакция в состоянии aborted  
UPDATE marketplace.profession  
SET salary = salary - 10000  
WHERE profession_id = 4;  
  
COMMIT;
```
Результат: запросы транзакции откатились, ничего в таблице не поменялось
<img width="809" height="97" alt="image" src="https://github.com/user-attachments/assets/1f7e25d6-5e00-4fae-ae73-fbca231811f6" />
<img width="797" height="109" alt="no car path" src="https://github.com/user-attachments/assets/fdc8e654-f17e-44c4-9223-284bac5bf0a4" />
## 1.READ UNCOMMITTED

### 1.1 Грязные данные
#### T1
```sql
BEGIN;
UPDATE marketplace.profession SET salary = 99999 WHERE name = 'Рекрутер';

```
#### T2
```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT name, salary FROM marketplace.profession WHERE name = 'Рекрутер';
```
<img width="341" height="84" alt="image" src="https://github.com/user-attachments/assets/4cd60a55-5d96-41b7-9e78-e4da82cebf30" />

#### T1

```sql
COMMIT;
```

#### T2
```sql
SELECT name, salary FROM marketplace.profession WHERE name = 'Рекрутер';
COMMIT;
```
<img width="337" height="85" alt="image" src="https://github.com/user-attachments/assets/e26ed08a-ee15-45e7-933c-873620a99fab" />


**Описание результатов**
Видим, что данные в T2 обновились только после COMMIT в T1, несмотря на выставленный уровень READ UNCOMMITTED

**ВЫВОД**
postgres не разрешает "грязные данные" даже с read uncommited

## 2.READ COMMITTED: неповторяющееся чтение

#### T1
```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Первое чтение
SELECT name, salary FROM marketplace.profession WHERE name = 'HR специалист';

-- Второе чтение
SELECT name, salary FROM marketplace.profession WHERE name = 'HR специалист';

COMMIT;
```
Если что этот запрос разбивается на 2
#### T2
```sql
BEGIN;
UPDATE marketplace.profession SET salary = 120000 WHERE name = 'HR специалист';
COMMIT;
```
Первое чтение:
<img width="344" height="81" alt="image" src="https://github.com/user-attachments/assets/7d9ea3b7-733a-446b-9d61-ff298c1c169d" />

Второе чтение:
<img width="343" height="86" alt="image" src="https://github.com/user-attachments/assets/de533232-6e95-4849-ae52-a4bc5405e005" />


**Описание результатов**
Данные поменялись при выполнении запроса и результаты запроса поменялись


**ВЫВОД**
Если во время выполнения T1, другая транзакция изменит данные, то T1 будет использовать изменённые данные

***

## **REPEATABLE READ**

### **Проверка, что T1 не видит изменений от T2 (Non-Repeatable Read)**


**Транзакция T1:**
 ```sql
    BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    -- Начальная цена товара с item_id = 5 равна 27000.
    SELECT price FROM marketplace.items WHERE item_id = 5;

    -- >> После этого выполняется транзакция T2.

    -- Повторяем тот же SELECT в рамках T1.
    SELECT price FROM marketplace.items WHERE item_id = 5;

    COMMIT;
```

**Транзакция T2:**
```sql
    BEGIN;
    UPDATE marketplace.items SET price = 500 WHERE item_id = 5;
    COMMIT;
```

**Краткое описание результата:**
    Первый `SELECT` в T1 вернул цену `27000`. После того как T2 изменила цену на `500` и закоммитила изменения, второй `SELECT` в T1 все равно вернул `27000`. Транзакция T1 не увидела изменений, сделанных T2, до своего собственного завершения.

<img width="157" height="69" alt="изображение" src="https://github.com/user-attachments/assets/2cb427a6-244c-4db3-ac7e-96fe33f4c79e" />
После Т2 в таблцие:

<img width="194" height="136" alt="изображение" src="https://github.com/user-attachments/assets/91c62543-da2f-4562-991f-2dc8b7c8a813" />
Повторный селект в рамках Т1:
<img width="159" height="97" alt="изображение" src="https://github.com/user-attachments/assets/b7651889-9b33-45ba-b0a2-923c03691f24" />

**Выводы:**
    Уровень изоляции `REPEATABLE READ` защищает от "неповторяющегося чтения" и гарантирует, что в течение всей транзакции данные, которые были прочитаны хотя бы раз, не изменятся, даже если другие транзакции вносят и фиксируют изменения в этих же строках.

***

### **Проверка на "фантомное чтение" (Phantom Read)**

**Транзакция T1:**
```sql

    BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    -- Считаем количество товаров в категории 1.
    -- Результат равен 12.
    SELECT COUNT(*) FROM marketplace.items WHERE category_id = 1;

    -- >> После этого выполняется транзакция T2, которая добавляет новый товар.

    -- Повторно считаем количество товаров в той же категории.
    SELECT COUNT(*) FROM marketplace.items WHERE category_id = 1;

    COMMIT;
```

**Транзакция T2:**
```sql
    BEGIN;
    INSERT INTO marketplace.items (shop_id, name, category_id, price)
    VALUES (1, 'Новый гаджет', 1, 999.00);
    COMMIT;
```

**Краткое описание результата:**
    Первый `SELECT COUNT(*)` в T1 вернул `12`. После того как T2 добавила новый товар в ту же категорию и закоммитила транзакцию, второй `SELECT COUNT(*)` в T1 снова вернул `12`. Новая строка ("фантом") не появилась в наборе данных транзакции T1.  

<img width="115" height="101" alt="изображение" src="https://github.com/user-attachments/assets/e22d26f7-27b7-4266-b216-5c55da21652f" />   
После Т2 количество стало:  
<img width="113" height="99" alt="изображение" src="https://github.com/user-attachments/assets/b676bd49-6130-46ea-898f-4819737b1fb7" />   
Повторный селект в рамках Т1:   
<img width="117" height="127" alt="изображение" src="https://github.com/user-attachments/assets/56aa0264-8df2-423b-9ec2-b6f1ee552267" />  



**Выводы:**
    В PostgreSQL реализация уровня `REPEATABLE READ` также защищает и от "фантомного чтения".  Если запрос сделал выборку по определённому условию, то до конца транзакции в результатах этого запроса не появятся новые строки, даже если другие транзакции их добавили

***

## SERIALIZABLE:
Смоделируй конфликт: две транзакции вставляют одинаковые данные.
Поймай ошибку could not serialize access due to concurrent update и повтори транзакцию.

Транзакция T1 - Начало
```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```
Транзакция T1 - Проверка существующих данных

```sql
SELECT login FROM marketplace.workers WHERE login LIKE 'serial_worker%';
```
<img width="257" height="171" alt="image" src="https://github.com/user-attachments/assets/24dc8471-c852-44ef-80bd-271268800876" />


Транзакция T1 - Вставка нового работника
```sql
INSERT INTO marketplace.workers (login, password_hash, salt)
VALUES ('serial_worker_001', 'hash_serial_001', 'salt_serial_001');
```
Транзакция T2 - Начало
```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```
Транзакция T2 - Проверка существующих данных
```sql
SELECT login FROM marketplace.workers WHERE login LIKE 'serial_worker%';
```
<img width="257" height="171" alt="image" src="https://github.com/user-attachments/assets/0bd6ed18-3e48-47b7-83d1-7705b4946eb6" />

Транзакция T2 - Вставка того же работника
```sql
INSERT INTO marketplace.workers (login, password_hash, salt)
VALUES ('serial_worker_001', 'hash_serial_001', 'salt_serial_001');
```
Транзакция T1 - Попытка коммита (УСПЕХ)
```sql
COMMIT;
```
Транзакция T2 - Попытка коммита (ОШИБКА)
```sql
COMMIT;
```

Результат:

<img width="921" height="269" alt="image" src="https://github.com/user-attachments/assets/811a3d64-332e-4097-85a3-29453c105f0c" />

После повторения транзакции (если что перед этим сделал rollback)

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT login FROM marketplace.workers WHERE login LIKE 'serial_worker%';
INSERT INTO marketplace.workers (login, password_hash, salt)
VALUES ('serial_worker_001', 'hash_serial_001', 'salt_serial_001');
COMMIT;
```

<img width="886" height="241" alt="image" src="https://github.com/user-attachments/assets/b6b87c6b-e959-43ed-8985-2f6253e35ca8" />



**Описание результатов**
При одновременной вставке одинаковых данных в SERIALIZABLE режиме одна из транзакций завершается ошибкой сериализации.

**ВЫВОД**
SERIALIZABLE уровень изоляции предотвращает конфликты параллельных транзакций, принудительно прерывая одну из них. Требуется обработка ошибок и перезапуск транзакций в приложении.

## **SAVEPOINT**

### **Транзакция с одной точкой сохранения**


```sql
    BEGIN;

    -- Добавляем нового работника.
    INSERT INTO marketplace.workers (login, password_hash, salt) VALUES ('new_worker_1', 'hash', 'salt');

    --  Устанавливаем точку сохранения после успешного действия.
    SAVEPOINT worker_added;

    -- Выполняем действие, которое приведет к ошибке (вставка с неверным внешним ключом).
    INSERT INTO marketplace.worker_assignments (worker_id, place_type, place_id, work_id)
    VALUES ((SELECT worker_id FROM marketplace.workers WHERE login = 'new_worker_1'), 'shop', 1, 999);

    -- >> Здесь psql вернет ошибку нарушения внешнего ключа.

    -- Откатываемся к точке сохранения, чтобы продолжить работу.
    ROLLBACK TO SAVEPOINT worker_added;

    -- Завершаем транзакцию, сохраняя изменения, сделанные до точки сохранения.
    COMMIT;
 ```
```sql
    -- Проверяем, что работник был успешно добавлен.
    SELECT * FROM marketplace.workers WHERE login = 'new_worker_1';

    -- Проверяем, что ошибочное назначение было отменено.
    SELECT * FROM marketplace.worker_assignments WHERE worker_id = (SELECT worker_id FROM marketplace.workers WHERE login = 'new_worker_1');
```

**Краткое описание результата:**
    После выполнения основной транзакции `SELECT` из таблицы `workers` вернул одну запись о новом работнике. `SELECT` из таблицы `worker_assignments` не вернул ничего. Это подтверждает, что вставка работника была сохранена, а ошибочная вставка назначения была успешно отменена из-за отката к `SAVEPOINT`.

<img width="615" height="81" alt="изображение" src="https://github.com/user-attachments/assets/e6d2d3b3-83e7-4b3e-8a8c-95b30e00773c" />
<img width="432" height="87" alt="изображение" src="https://github.com/user-attachments/assets/c0217982-df7c-46ae-91b9-ad130a112223" />


**Выводы:**
    SAVEPOINT позволяет отменить не всю транзакцию, а только её часть, выполненную после точки сохранения

***

### **Транзакция с двумя точками сохранения**


```sql
    BEGIN;

    -- Создаем покупку.
    INSERT INTO marketplace.purchases (item_id, buyer_id, status) VALUES (3, 2, 'pending') RETURNING purchase_id;

    -- Устанавливаем первую точку сохранения.
    SAVEPOINT purchase_created;

    -- Создаем связанный с покупкой заказ.
    INSERT INTO marketplace.orders (purchase_id, pvz_id, status) VALUES (51, 1, 'created');

    -- Устанавливаем вторую точку сохранения.
    SAVEPOINT order_created;

    -- Решаем отменить заказ, но оставить покупку.
    -- Откатываемся к первой точке сохранения.
    ROLLBACK TO SAVEPOINT purchase_created;

    -- Фиксируем транзакцию.
    COMMIT;
```

```sql
    -- Проверяем, что покупка осталась в базе данных.
    SELECT * FROM marketplace.purchases WHERE purchase_id = 10;

    -- Проверяем, что заказ был удален в результате отката.
    SELECT * FROM marketplace.orders WHERE purchase_id = 10;
```

**Краткое описание результата:**
    Первый проверочный `SELECT` успешно нашел запись о покупке с `purchase_id = 10`. Второй `SELECT` не вернул ни одной строки, подтверждая, что запись о заказе, созданная после `SAVEPOINT purchase_created`, была отменена.

**До запроса:**  
![Без имени](https://github.com/user-attachments/assets/7415d04b-3300-4994-9440-9cefc1833c88)
<img width="649" height="45" alt="Без имени" src="https://github.com/user-attachments/assets/6806857e-6c6f-4a30-aae1-1cd55f69969a" />  
**После выполнения:**  
<img width="632" height="76" alt="Без имени" src="https://github.com/user-attachments/assets/003ce35c-a661-442f-8a5c-9a5676b88f37" />
<img width="645" height="47" alt="Без имени" src="https://github.com/user-attachments/assets/74c4b12e-0ea4-431d-8052-2320cee3864b" />


**Выводы:**
    Можно использовать несколько `SAVEPOINT` внутри одной транзакции. Откат к более ранней точке сохранения (`purchase_created`) автоматически отменяет все действия, выполненные после нее, включая создание более поздних точек сохранения (`order_created`).
