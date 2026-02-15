# CTE

## 1. Найти "лояльных" покупателей (более 2	покупок) и дату их последней покупки.
```sql
WITH LoyalBuyers AS (
    SELECT buyer_id 
    FROM marketplace.purchases
    GROUP BY buyer_id
    HAVING COUNT(purchase_id) > 2
)

SELECT b.login, MAX(p.purchase_date) AS last_purchase_date
FROM marketplace.purchases p
JOIN LoyalBuyers lb ON p.buyer_id = lb.buyer_id 
JOIN marketplace.buyers b ON p.buyer_id = b.buyer_id 
GROUP BY b.login, p.buyer_id
ORDER BY last_purchase_date DESC;
```
<img width="398" height="294" alt="изображение" src="https://github.com/user-attachments/assets/75a85f51-392f-4930-ae0c-667d72b078fc" />


## 2. ​Определить самый прибыльный магазин.
```sql
WITH ProfitShops AS (
	SELECT sh.shop_id, SUM(i.price) as total_profit
	FROM marketplace.purchases p
	JOIN marketplace.items i ON p.item_id = i.item_id
	JOIN marketplace.shops sh ON i.shop_id = sh.shop_id
	GROUP BY sh.shop_id
)

SELECT sh.name, ps.total_profit
FROM ProfitShops ps
JOIN marketplace.shops sh ON sh.shop_id = ps.shop_id
ORDER BY ps.total_profit DESC
LIMIT 1;
```
<img width="299" height="74" alt="изображение" src="https://github.com/user-attachments/assets/d6f20e73-cc67-4ade-a281-cbc408be7ee3" />

## 3. Найти работников в ПВЗ с наибольшим количеством заказов.
```sql
WITH PvzWorkersOrders AS (
	SELECT w.worker_id, COUNT(o.order_id) as orders_count
	FROM marketplace.orders o
	JOIN marketplace.worker_assignments wa ON o.pvz_id = wa.place_id
	JOIN marketplace.workers w ON wa.worker_id = w.worker_id
	GROUP BY w.worker_id
)

SELECT w.login, pwo.orders_count
FROM PvzWorkersOrders pwo
JOIN marketplace.workers w ON pwo.worker_id = w.worker_id
WHERE pwo.orders_count = (SELECT MAX(orders_count) FROM PvzWorkersOrders)
ORDER BY w.login;
```
<img width="309" height="267" alt="изображение" src="https://github.com/user-attachments/assets/55d4e943-77e4-4b33-af63-717c230d13a3" />

## 4. Получить список товаров из самой "дорогой" категории (по средней цене).
```sql
WITH CategoryCost AS (
	SELECT c.category_id, AVG(i.price) as avg_category_cost
	FROM marketplace.category_of_item c 
	JOIN marketplace.items i ON c.category_id = i.category_id
	GROUP BY c.category_id
)

SELECT i.item_id, i.name, c.name, cc.avg_category_cost
FROM marketplace.category_of_item c 
JOIN marketplace.items i ON c.category_id = i.category_id
JOIN CategoryCost cc ON c.category_id = cc.category_id
WHERE cc.avg_category_cost = (SELECT MAX(avg_category_cost) FROM CategoryCost);
```
<img width="635" height="339" alt="изображение" src="https://github.com/user-attachments/assets/5f1a370a-cd40-4be9-8487-7647321ee2b8" />

## 5. Найти магазины с количеством товаров выше среднего  
```sql
WITH ShopItemCounts AS (
    SELECT shop_id, COUNT(item_id) AS item_count
    FROM marketplace.items
    GROUP BY shop_id
),
AverageItemCount AS (
    SELECT AVG(item_count) AS avg_count
    FROM ShopItemCounts
)

SELECT s.name, sic.item_count, aic.avg_count
FROM ShopItemCounts sic
JOIN marketplace.shops s ON sic.shop_id = s.shop_id
CROSS JOIN AverageItemCount aic
WHERE sic.item_count > aic.avg_count
ORDER BY sic.item_count DESC;
```
<img width="433" height="170" alt="изображение" src="https://github.com/user-attachments/assets/c30a3abe-5d4b-409d-9e27-c6be6d3ebd78" />

# UNION
## 1. Объединение логинов работников и покупателей

```sql
SELECT login, 'worker' AS user_type FROM marketplace.workers
UNION
SELECT login, 'buyer' AS user_type FROM marketplace.buyers;
```
<img width="375" height="176" alt="image" src="https://github.com/user-attachments/assets/2756096e-c970-47bf-b069-80234d98bf05" />

## 2. Товары из двух категорий

```sql
SELECT item_id, name, price FROM marketplace.items WHERE category_id = 1
UNION
SELECT item_id, name, price FROM marketplace.items WHERE category_id = 2;
```
<img width="691" height="175" alt="image" src="https://github.com/user-attachments/assets/45edfe42-ebd6-4796-993c-05fce85a321d" />

## 3. Все существующие статусы покупок и заказов

```sql
SELECT DISTINCT status, 'purchase' AS type FROM marketplace.purchases
UNION
SELECT DISTINCT status, 'orders' FROM marketplace.orders;
```
<img width="328" height="204" alt="image" src="https://github.com/user-attachments/assets/713e2806-a393-47f9-9316-eb2bb87e43cc" />

# INTERSECT
## 1. Работники, которые также являются владельцами магазинов

```sql
SELECT worker_id FROM marketplace.workers
INTERSECT
SELECT owner_id FROM marketplace.shops WHERE owner_id IS NOT NULL;
```
<img width="199" height="176" alt="image" src="https://github.com/user-attachments/assets/73aa6d82-c1b9-4678-840f-ce1b95b6dceb" />

## 2. Категории товаров, по которым есть и товары, и заказы

```sql
SELECT category_id FROM marketplace.items
INTERSECT
SELECT i.category_id
FROM marketplace.items i
JOIN marketplace.purchases p ON i.item_id = p.item_id;
```
<img width="206" height="177" alt="image" src="https://github.com/user-attachments/assets/1084fd41-7384-43cc-b967-7d9af943c0d6" />

## 3. ПВЗ, используемые в заказах и имеющие назначенных работников

```sql
SELECT pvz_id FROM marketplace.orders
INTERSECT
SELECT place_id FROM marketplace.worker_assignments WHERE place_type = 'pvz';
```
<img width="167" height="206" alt="image" src="https://github.com/user-attachments/assets/18ce9c44-7393-4736-8908-3ffaab77f007" />

# EXCEPT
## 1. Работники без назначений

```sql
SELECT worker_id FROM marketplace.workers
EXCEPT
SELECT worker_id FROM marketplace.worker_assignments;
```
<img width="191" height="182" alt="image" src="https://github.com/user-attachments/assets/305de34b-915a-4ead-b244-6107aea2994e" />

## 2. Товары без покупок

```sql
SELECT item_id FROM marketplace.items
EXCEPT
SELECT item_id FROM marketplace.purchases;
```
<img width="180" height="173" alt="image" src="https://github.com/user-attachments/assets/95bdb333-c62a-4e68-92c6-f541dab72c36" />

## 3. Покупатели без отзывов

```sql
SELECT buyer_id FROM marketplace.buyers
EXCEPT
SELECT p.buyer_id
FROM marketplace.purchases p
JOIN marketplace.reviews r ON p.purchase_id = r.purchase_id;
```
<img width="180" height="57" alt="image" src="https://github.com/user-attachments/assets/82b0ad1e-7309-462c-9fd1-67083d769f19" />

# PARTITION BY
## 1. Сравнить цену каждого товара со средней ценой в его категории. 
```sql
SELECT name, price, category_id, AVG(price) OVER (PARTITION BY category_id) AS avg_price_in_category
FROM marketplace.items;
```
<img width="651" height="467" alt="изображение" src="https://github.com/user-attachments/assets/cf5987b3-22fc-47ee-89da-ab0c8a31507a" />

## 2. Показать каждую покупку и среднюю цену всех покупок этого покупателя
```sql
SELECT b.login, i.name, i.price, AVG(i.price) OVER (PARTITION BY p.buyer_id) as avg_purchase_price
FROM marketplace.purchases p
JOIN marketplace.buyers b ON p.buyer_id = b.buyer_id
JOIN marketplace.items i ON p.item_id = i.item_id;
```
<img width="730" height="466" alt="изображение" src="https://github.com/user-attachments/assets/578cdb99-0679-409b-a9d7-5fc9fb87509c" />

# PARTITION BY + ORDER BY
## 1. Ранжирование товаров по цене внутри каждой категории

```sql
SELECT
    item_id,
    name,
    category_id,
    price,
    ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS price_rank
FROM marketplace.items
ORDER BY category_id, price_rank;
```
<img width="927" height="170" alt="image" src="https://github.com/user-attachments/assets/5cd7442b-c7cc-4dc9-8e99-82c12fddaa4c" />

## 2. Нумерация покупок для каждого покупателя по дате

```sql
SELECT
    purchase_id,
    buyer_id,
    item_id,
    purchase_date,
    status,
    ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_date) AS purchase_number
FROM marketplace.purchases
ORDER BY buyer_id, purchase_number;
```
<img width="1072" height="179" alt="image" src="https://github.com/user-attachments/assets/03eddd04-85fb-4edc-820b-47214ba521ee" />


# ROWS
## 1. Cкользящее среднее зарплаты по профессиям
```sql
SELECT 
    profession_id,
    name,
    salary,
    AVG(salary) OVER (
        ORDER BY salary
        ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
    ) AS avg_salary_5_rows
FROM marketplace.profession
ORDER BY salary;
```
<img width="656" height="172" alt="image" src="https://github.com/user-attachments/assets/d4e121b9-522b-45fd-b4cd-1dbdb573a5ee" />

## 2. Накопленная сумма цен товаров по магазинам
```sql
SELECT 
    shop_id,
    name,
    price,
    SUM(price) OVER (
        PARTITION BY shop_id
        ORDER BY price
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_price
FROM marketplace.items
ORDER BY shop_id, price;
```
<img width="634" height="299" alt="image" src="https://github.com/user-attachments/assets/2b42d965-5003-4dde-b313-9b68b05dc9fe" />

# RANGE
## 1. Профессии в диапазоне ±5000 от текущей зарплаты
```sql
SELECT 
    profession_id,
    name,
    salary,
    COUNT(*) OVER (
        ORDER BY salary
        RANGE BETWEEN 5000 PRECEDING AND 5000 FOLLOWING
    ) AS similar_salary_count
FROM marketplace.profession
ORDER BY salary;
```
<img width="648" height="169" alt="image" src="https://github.com/user-attachments/assets/79e7ead2-3bb8-4fe8-b575-2fe7988b47d8" />

## 2. Средние рейтинги в пределах ±1 балла
```sql
SELECT 
    review_id,
    rating,
    description,
    AVG(rating) OVER (
        ORDER BY rating
        RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS avg_rating_range
FROM marketplace.reviews
ORDER BY rating;
```
<img width="651" height="302" alt="image" src="https://github.com/user-attachments/assets/bf006675-5fa2-4815-99fb-c40ad5c3992e" />

# ROW_NUMBER()
## 1. Пронумеровать всех работников в алфавитном порядке.  
```sql
SELECT login, ROW_NUMBER() OVER (ORDER BY login ASC) AS row_num
FROM marketplace.workers;
```
<img width="291" height="291" alt="изображение" src="https://github.com/user-attachments/assets/ae6e9990-3c73-405f-99e1-093a8ca01fae" />

# RANK()
## 1. Ранжировать товары по цене от самого дорогого к самому дешевому.  
```sql
SELECT name, price, RANK() OVER (ORDER BY price DESC) as price_rank
FROM marketplace.items
ORDER BY price_rank;
```
<img width="488" height="394" alt="изображение" src="https://github.com/user-attachments/assets/f7faa405-16f5-4daf-85a5-cba8c2c67b5d" />

# DENSE_RANK()
## 1. Ранжировать профессии по уровню зарплаты.  
```sql
SELECT name, salary, DENSE_RANK() OVER (ORDER BY salary DESC) as salary_rank
FROM marketplace.profession
ORDER BY salary_rank;
```
<img width="487" height="420" alt="изображение" src="https://github.com/user-attachments/assets/44db103a-2a27-4c69-86d8-a4318867dee0" />


# LAG
## Сравнение зарплаты с предыдущими по зарплате + сортировка для удобного вывода
```sql
SELECT 
    p.profession_id,
    p.name,
    p.salary,
    LAG(p.salary) OVER (ORDER BY p.salary) AS prev_salary,
    p.salary - LAG(p.salary) OVER (ORDER BY p.salary) AS salary_diff_prev
FROM marketplace.profession p
ORDER BY p.salary;
```
<img width="739" height="177" alt="image" src="https://github.com/user-attachments/assets/70490682-178e-4f31-94af-4ba1128095d5" />

# LEAD
## Следующая покупка пользователя
```sql
SELECT 
    purchase_id,
    buyer_id,
    item_id,
    purchase_date,
    LEAD(purchase_date) OVER (
        PARTITION BY buyer_id 
        ORDER BY purchase_date
    ) AS next_purchase_date,
    LEAD(item_id) OVER (
        PARTITION BY buyer_id 
        ORDER BY purchase_date
    ) AS next_purchased_item
FROM marketplace.purchases
ORDER BY buyer_id, purchase_date;
```
<img width="1014" height="301" alt="image" src="https://github.com/user-attachments/assets/dbd4f002-4c4f-437f-bdc9-ca6e6536ad4c" />

# FIRST_VALUE
## Самый дешевый товар в категории
```sql
SELECT 
    item_id,
    name,
    category_id,
    price,
    FIRST_VALUE(name) OVER (
        PARTITION BY category_id 
        ORDER BY price
    ) AS cheapest_item_name,
    FIRST_VALUE(price) OVER (
        PARTITION BY category_id 
        ORDER BY price
    ) AS cheapest_item_price
FROM marketplace.items
ORDER BY category_id, price;
```
<img width="997" height="298" alt="image" src="https://github.com/user-attachments/assets/b7a3be61-c3b6-4021-8f66-52f2a67679ad" />

# LAST_VALUE
## Самый дорогой товар в категории
```sql
SELECT 
    item_id,
    name,
    category_id,
    price,
    LAST_VALUE(name) OVER (
        PARTITION BY category_id 
        ORDER BY price
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS most_expensive_item_name,
    LAST_VALUE(price) OVER (
        PARTITION BY category_id 
        ORDER BY price
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS most_expensive_item_price
FROM marketplace.items
ORDER BY category_id, price;
```
<img width="1087" height="299" alt="image" src="https://github.com/user-attachments/assets/e48e5155-f076-4de0-933b-022d45535efc" />
