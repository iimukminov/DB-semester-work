#### 1. Список всех покупателей
```sql
SELECT * FROM marketplace.buyers;
```
РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА — 
<img width="606" height="142" alt="изображение" src="https://github.com/user-attachments/assets/086f4cbf-bb61-46d9-8664-72a8a2cbff0a" />


#### 2. Список всех товаров с ценой
```sql
SELECT name, price FROM marketplace.items;
```
РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА — 
<img width="316" height="144" alt="изображение" src="https://github.com/user-attachments/assets/fbf01301-e69f-446f-9f48-9b9539fb30a9" />


#### 3. Метка для дорогих и дешёвых товаров
```sql
SELECT name, price, CASE WHEN price > 10000 THEN 'Дорогой' ELSE 'Дешевый' END AS price_tag FROM marketplace.items;
```
РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА — 
<img width="396" height="144" alt="изображение" src="https://github.com/user-attachments/assets/2fc0ac97-bad1-4c28-9f57-9f7247d881d7" />


#### 4. Категоризация отзывов по рейтингу
```sql
SELECT review_id, rating, CASE WHEN rating >= 4 THEN 'Положительный' WHEN rating = 3 THEN 'Нейтральный' ELSE 'Негативный' END AS review_type FROM marketplace.reviews;
```
РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА — 
<img width="321" height="143" alt="изображение" src="https://github.com/user-attachments/assets/b70f159f-5373-4909-980c-00e568281ee2" />


#### 5. Заказы с логинами покупателей
```sql
SELECT orders.order_id, buyers.login 
FROM marketplace.orders AS orders
INNER JOIN marketplace.purchases AS purchases ON orders.purchase_id = purchases.purchase_id
INNER JOIN marketplace.buyers AS buyers ON purchases.buyer_id = buyers.buyer_id;
```
РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА — 
<img width="276" height="144" alt="изображение" src="https://github.com/user-attachments/assets/5c0f5d4a-7115-4678-8ee1-88f32f8eb736" />


#### 6. Товары и их магазины
```sql
SELECT items.name, shops.name 
FROM marketplace.items AS items
INNER JOIN marketplace.shops AS shops ON items.shop_id = shops.shop_id;
```
РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА — 
<img width="362" height="142" alt="изображение" src="https://github.com/user-attachments/assets/31d3c58a-a416-48a5-b833-3e0e781e6a91" />


#### 7. Все магазины и их владельцы (включая без владельца)
```sql
SELECT shops.name, workers.login 
FROM marketplace.shops AS shops
LEFT JOIN marketplace.workers AS workers ON shops.owner_id = workers.worker_id;
```
РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА — 
<img width="363" height="139" alt="изображение" src="https://github.com/user-attachments/assets/d0ca25d6-195a-4865-9764-e8f0290e701c" />


#### 8. Все покупатели и их отзывы (даже если отзывов нет)
```sql
SELECT buyers.login, reviews.review_id 
FROM marketplace.buyers AS buyers
LEFT JOIN marketplace.purchases AS purchases ON buyers.buyer_id = purchases.buyer_id 
LEFT JOIN marketplace.reviews AS reviews ON purchases.purchase_id = reviews.purchase_id;
```
РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА — 
<img width="284" height="141" alt="изображение" src="https://github.com/user-attachments/assets/72d1724b-b50e-4099-9be2-21fcd68f0cb8" />


#### 9. Все работники и их назначения (даже если нет работника)
```sql
SELECT workers.login, worker_assignments.place_id 
FROM marketplace.workers AS workers
RIGHT JOIN marketplace.worker_assignments AS worker_assignments ON workers.worker_id = worker_assignments.worker_id;
```
РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА — 
<img width="282" height="143" alt="изображение" src="https://github.com/user-attachments/assets/b93923e6-7ed3-485f-840d-40e3175507a8" />


#### 10. Заказы и соответствующие покупки (покажет все заказы)
```sql
SELECT orders.order_id, purchases.purchase_id
FROM marketplace.orders AS orders
RIGHT JOIN marketplace.purchases AS purchases ON orders.purchase_id = purchases.purchase_id;
```
РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА — 
<img width="220" height="141" alt="изображение" src="https://github.com/user-attachments/assets/8c700e3d-2518-488c-a5f2-3221cb62071a" />


#### 11. Все товары и все магазины (в том числе без пары)
```sql
SELECT items.name, shops.name 
FROM marketplace.items AS items
FULL OUTER JOIN marketplace.shops AS shops ON items.shop_id = shops.shop_id;
```
РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА — 
<img width="360" height="143" alt="изображение" src="https://github.com/user-attachments/assets/79f5bc42-d499-4eba-8e2f-946b1babb94b" />


#### 12. Все отзывы и покупки (даже если не связаны)
```sql
SELECT reviews.review_id, purchases.purchase_id 
FROM marketplace.reviews AS reviews
FULL OUTER JOIN marketplace.purchases AS purchases ON reviews.purchase_id = purchases.purchase_id;
```
РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА — 
<img width="225" height="138" alt="изображение" src="https://github.com/user-attachments/assets/919d2bba-6259-45ba-9267-cb86a7d4f7b5" />


#### 13. Все сочетания категорий и магазинов
```sql
SELECT category_of_item.name, shops.name 
FROM marketplace.category_of_item AS category_of_item
CROSS JOIN marketplace.shops AS shops;
```
РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА — 
<img width="356" height="439" alt="изображение" src="https://github.com/user-attachments/assets/22ee124e-6ad3-402a-bca7-ce7ba1d1085c" />


#### 14. Все сочетания покупателей и товаров
```sql
SELECT buyers.login, items.name 
FROM marketplace.buyers AS buyers
CROSS JOIN marketplace.items AS items;
```
РЕЗУЛЬТАТ ВЫПОЛНЕНИЯ ЗАПРОСА — 
<img width="359" height="441" alt="изображение" src="https://github.com/user-attachments/assets/0fbf220b-5a4c-4845-bd95-f0e92a43abed" />
