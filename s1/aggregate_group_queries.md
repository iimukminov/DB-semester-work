
### 1. COUNT()

#### 1.1. Общее количество покупателей  
```sql
SELECT COUNT(*) AS total_buyers FROM marketplace.buyers;
```
![](assets/Pasted%20image%2020251028232957.png)
#### 1.2. Количество товаров в каждом магазине  
```sql
SELECT shop_id, COUNT(*) AS items_count FROM marketplace.items GROUP BY shop_id;
```
![](assets/Pasted%20image%2020251028233008.png)
### 2. SUM()

#### 2.1. Общая сумма покупок каждого покупателя  
```sql
SELECT buyer_id, SUM(price) AS total_spent
FROM marketplace.purchases
JOIN marketplace.items ON purchases.item_id = items.item_id
GROUP BY buyer_id;
```
![](assets/Pasted%20image%2020251028233040.png)
#### 2.2. Общая сумма заказов по статусу  
```sql
SELECT status, SUM(price) AS total_order_amount
FROM marketplace.orders
JOIN marketplace.purchases ON orders.purchase_id = purchases.purchase_id
JOIN marketplace.items ON purchases.item_id = items.item_id
GROUP BY status;
```
![](assets/Pasted%20image%2020251028233224.png)
### 3. AVG()

#### 3.1. Средняя цена товаров в каждой категории  
```sql
SELECT category_id, AVG(price) AS avg_price
FROM marketplace.items
GROUP BY category_id;
```
![](assets/Pasted%20image%2020251028233235.png)
#### 3.2. Средний рейтинг отзывов  
```sql
SELECT AVG(rating) AS avg_rating FROM marketplace.reviews;
```
![](assets/Pasted%20image%2020251028233244.png)
### 4. MIN()

#### 4.1. Минимальная цена товара в каждом магазине  
```sql
SELECT shop_id, MIN(price) AS min_price
FROM marketplace.items
GROUP BY shop_id;
```
![](assets/Pasted%20image%2020251028233259.png)
#### 4.2. Самый ранний заказ (по дате)  
```sql
SELECT MIN(order_date) AS earliest_order FROM marketplace.orders;
```
![](assets/Pasted%20image%2020251028233311.png)
### 5. MAX()

#### 5.1. Максимальная цена товара в каждом магазине  
```sql
SELECT shop_id, MAX(price) AS max_price
FROM marketplace.items
GROUP BY shop_id;
```
![](assets/Pasted%20image%2020251028233337.png)
#### 5.2. Самый поздний заказ (по дате)  
```sql
SELECT MAX(order_date) AS latest_order FROM marketplace.orders;
```
![](assets/Pasted%20image%2020251028233351.png)
### 6. STRING_AGG()

#### 6.1. Список товаров в каждом магазине в одной строке  
```sql
SELECT shop_id, STRING_AGG(name, ', ') AS products_list
FROM marketplace.items
GROUP BY shop_id;
```
![](assets/Pasted%20image%2020251028233410.png)
#### 6.2. Список отзывов и их описаний для каждого покупателя  
```sql
SELECT purchases.buyer_id, STRING_AGG(reviews.description, '; ') AS reviews_text
FROM marketplace.reviews
JOIN marketplace.purchases ON reviews.purchase_id = purchases.purchase_id
GROUP BY purchases.buyer_id;
```
![](assets/Pasted%20image%2020251028233423.png)
### 7. SELECT, FROM, GROUP BY, HAVING

#### 7.1 выручка по категориям для покупок, показывать только категории с суммой более 1000.
```sql
SELECT
  c.category_id,
  c.name       AS category_name,
  SUM(i.price) AS revenue
FROM marketplace.purchases p
JOIN marketplace.items i  ON i.item_id = p.item_id
JOIN marketplace.category_of_item c ON c.category_id = i.category_id
GROUP BY c.category_id, c.name
HAVING SUM(i.price) > 1000
```
![](assets/Pasted%20image%2020251028231956.png)
#### 7.2  заказы по ПВЗ, показывать только ПВЗ с 10+ доставок.
```sql
SELECT
  o.pvz_id,
  COUNT(*) AS delivered_count
FROM marketplace.orders o
GROUP BY o.pvz_id
HAVING COUNT(*) >= 10
```
![](assets/Pasted%20image%2020251028232220.png)
### 8. GROUPING SETS

#### 8.1 выручка по магазину, по категории и общий итог.
```sql
SELECT
  s.shop_id,
  s.name        AS shop_name,
  c.category_id,
  c.name        AS category_name,
  SUM(i.price)  AS revenue
FROM marketplace.purchases p
JOIN marketplace.items i  ON i.item_id = p.item_id
JOIN marketplace.shops s  ON s.shop_id = i.shop_id
JOIN marketplace.category_of_item c ON c.category_id = i.category_id
WHERE p.status = 'completed'
GROUP BY GROUPING SETS (
  (s.shop_id, s.name),
  (c.category_id, c.name),
  ()
)
ORDER BY s.shop_id NULLS FIRST, c.category_id NULLS FIRST;
```
![](assets/Pasted%20image%2020251028232257.png)
#### 8.2 число заказов по ПВЗ и статусу, по ПВЗ, по статусу и общий итог.

```sql
SELECT
  o.pvz_id,
  p.status,
  COUNT(*) AS orders_count
FROM marketplace.orders o
JOIN marketplace.purchases p ON p.purchase_id = o.purchase_id
GROUP BY GROUPING SETS (
  (o.pvz_id, p.status),
  (o.pvz_id),
  (p.status),
  ()
)
ORDER BY o.pvz_id NULLS LAST, p.status NULLS LAST;
```
![](assets/Pasted%20image%2020251028232325.png)
### 9. ROLLUP
#### 9.1 выручка по магазину и категории с подытогами по магазину и общим итогом.

```sql
SELECT
  s.shop_id,
  s.name        AS shop_name,
  c.category_id,
  c.name        AS category_name,
  SUM(i.price)  AS revenue
FROM marketplace.purchases p
JOIN marketplace.items i  ON i.item_id = p.item_id
JOIN marketplace.shops s  ON s.shop_id = i.shop_id
JOIN marketplace.category_of_item c ON c.category_id = i.category_id
WHERE p.status = 'completed'
GROUP BY ROLLUP (s.shop_id, s.name, c.category_id, c.name)
ORDER BY s.shop_id NULLS LAST, c.category_id NULLS LAST;
```
![](assets/Pasted%20image%2020251028232351.png)
#### 9.2 число заказов по ПВЗ и статусу с подытогами по ПВЗ и общим итогом.
```sql
SELECT
  o.pvz_id,
  o.status,
  COUNT(*) AS orders_count
FROM marketplace.orders o
GROUP BY ROLLUP (o.pvz_id, o.status)
ORDER BY o.pvz_id NULLS LAST, o.status NULLS LAST;
```
![](assets/Pasted%20image%2020251028232411.png)
### 10. CUBE
#### 10.1 число покупок по покупателю и статусу со всеми комбинациями и общим итогом.

```sql
SELECT
  p.buyer_id,
  p.status,
  COUNT(*) AS purchases_count
FROM marketplace.purchases p
GROUP BY CUBE (p.buyer_id, p.status)
ORDER BY p.buyer_id NULLS LAST, p.status NULLS LAST;
```
![](assets/Pasted%20image%2020251028232433.png)
#### 10.2 число товаров по магазину и категории со всеми комбинациями.
```sql
SELECT
  i.shop_id,
  i.category_id,
  COUNT(*) AS items_count
FROM marketplace.items i
GROUP BY CUBE (i.shop_id, i.category_id)
ORDER BY i.shop_id NULLS LAST, i.category_id NULLS LAST;
```
![](assets/Pasted%20image%2020251028232519.png)
### 11. SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY

#### 11.1 выручка по категориям для завершённых покупок, показывать только категории с суммой более 1000, по убыванию выручки.
```sql
SELECT
  c.category_id,
  c.name       AS category_name,
  SUM(i.price) AS revenue
FROM marketplace.purchases p
JOIN marketplace.items i  ON i.item_id = p.item_id
JOIN marketplace.category_of_item c ON c.category_id = i.category_id
WHERE p.status = 'completed'
GROUP BY c.category_id, c.name
HAVING SUM(i.price) > 1000
ORDER BY revenue DESC, c.category_id;
```
![](assets/Pasted%20image%2020251028232623.png)
#### 11.2 доставленные за последние 30 дней заказы по ПВЗ, показывать только ПВЗ с 1+ доставок, по убыванию количества.
```sql
SELECT
  o.pvz_id,
  COUNT(*) AS delivered_count
FROM marketplace.orders o
WHERE o.status = 'delivered'
  AND o.order_date >= NOW() - INTERVAL '30 days'
GROUP BY o.pvz_id
HAVING COUNT(*) >= 1
ORDER BY delivered_count DESC, o.pvz_id;
```
![](assets/Pasted%20image%2020251028232649.png)
