### Шаг 1. Запуск и подключение

1. Положите ваш `docker-compose.yml` в папку и выполните команду запуска:
```bash
docker compose up -d
```
2. Подключитесь к консоли MongoDB (она называется `mongosh`) прямо внутри контейнера:

```bash
   docker compose exec mongodb mongosh -u root -p root
```

---

### Шаг 2. Создание БД, коллекций и наполнение (Insert)

Вставьте эти команды в консоль `mongosh`.
*Мы создадим интернет-магазин: коллекции `users`, `products` и `orders`. Мы зададим `_id` вручную, чтобы точно и красиво
связать их в заказах.*

```javascript
// 1. Создаем базу данных (или переключаемся на нее)
use
online_store;

// 2. Наполняем коллекцию 'users' (Хранит вложенный JSON-объект address и массив interests)
db.users.insertMany([
    {
        _id: ObjectId("60d5ec49f1b2c8b1f8e4e1a1"),
        name: "Иван Иванов",
        address: {city: "Москва", street: "Ленина, 10"},
        interests: ["электроника", "спорт"]
    },
    {
        _id: ObjectId("60d5ec49f1b2c8b1f8e4e1a2"),
        name: "Анна Смирнова",
        address: {city: "Санкт-Петербург", street: "Невский, 5"},
        interests: ["книги", "музыка"]
    }
]);

// 3. Наполняем коллекцию 'products'
db.products.insertMany([
    {
        _id: ObjectId("60d5ec49f1b2c8b1f8e4e2b1"),
        name: "Умные часы",
        price: 15000,
        specs: {color: "black", battery: "300mAh"}
    },
    {
        _id: ObjectId("60d5ec49f1b2c8b1f8e4e2b2"),
        name: "Наушники",
        price: 8000,
        specs: {color: "white", anc: true}
    }
]);

// 4. Наполняем коллекцию 'orders' (Связываем коллекции через ObjectId)
db.orders.insertMany([
    {
        user_id: ObjectId("60d5ec49f1b2c8b1f8e4e1a1"),    // Ссылка на Ивана
        product_id: ObjectId("60d5ec49f1b2c8b1f8e4e2b1"), // Ссылка на часы
        amount: 1,
        status: "completed"
    },
    {
        user_id: ObjectId("60d5ec49f1b2c8b1f8e4e1a2"),    // Ссылка на Анну
        product_id: ObjectId("60d5ec49f1b2c8b1f8e4e2b2"), // Ссылка на наушники
        amount: 2,
        status: "pending"
    }
]);
```

---

### Шаг 3. Запросы выборки (Find)

**Запрос 1: Обычный поиск по вложенному объекту**
Найдем пользователя, который живет в Москве (обратите внимание на синтаксис с точкой в кавычках):

```javascript
db.users.find({"address.city": "Москва"});
```

```text
online_store;> db.users.find({"address.city": "Москва"});
[
  {
    _id: ObjectId('60d5ec49f1b2c8b1f8e4e1a1'),
    name: 'Иван Иванов',
    address: { city: 'Москва', street: 'Ленина, 10' },
    interests: [ 'электроника', 'спорт' ]
  }
]
```

**Запрос 2: Поиск с проекцией (Projection)**
Выведем все товары, но покажем **только** название и цену (скроем системный `_id` и характеристики). `1` означает "
показать", `0` — "скрыть":

```javascript
db.products.find({}, {name: 1, price: 1, _id: 0});
```

```text
online_store;> db.products.find({}, {name: 1, price: 1, _id: 0});
[
  { name: 'Умные часы', price: 15000 },
  { name: 'Наушники', price: 8000 }
]
```

---

### Шаг 4. Запросы обновления (Update)

В MongoDB обновления используют специальные операторы, такие как `$set`, чтобы не перезаписать весь документ целиком.

**Запрос 1: Обновление одного документа (`updateOne`)**
Изменим статус заказа у Анны с `pending` на `shipped`:

```javascript
db.orders.updateOne(
    {user_id: ObjectId("60d5ec49f1b2c8b1f8e4e1a2")}, // Фильтр (кого ищем)
    {$set: {status: "shipped"}}                    // Что меняем
);
```

```text
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
```

**Запрос 2: Массовое обновление (`updateMany`)**
Сделаем наценку на все товары на 10%. Используем математический оператор `$mul` (умножение):

```javascript
db.products.updateMany(
    {},                            // Пустой фильтр = применить ко всем
    {$mul: {price: 1.10}}      // Умножить поле price на 1.1
);
```

```text
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 2,
  modifiedCount: 2,
  upsertedCount: 0
}

online_store> db.products.find({}, {name: 1, price: 1, _id: 0});
[
  { name: 'Умные часы', price: 16500 },
  { name: 'Наушники', price: 8800 }
]
```

---

### Шаг 5. Агрегация (Aggregate)

Агрегация в MongoDB — это конвейер (pipeline). Данные проходят через стадии по очереди.
Так как мы связали коллекции через `ObjectId`, самое крутое, что мы можем сделать — это аналог SQL `JOIN`. В MongoDB за
это отвечает стадия **`$lookup`**.

Давайте выведем все заказы, но вместо голого `user_id` подтянем информацию о самом покупателе из коллекции `users`:

```javascript
db.orders.aggregate([
    {
        $lookup: {
            from: "users",             // К какой коллекции присоединяемся
            localField: "user_id",     // Поле в текущей коллекции (orders)
            foreignField: "_id",       // Поле в присоединяемой коллекции (users)
            as: "customer_details"     // Как назвать новое поле с результатом
        }
    }
]);
```

```text
[
  {
    _id: ObjectId('69fa49bbf908a8113644ba89'),
    user_id: ObjectId('60d5ec49f1b2c8b1f8e4e1a1'),
    product_id: ObjectId('60d5ec49f1b2c8b1f8e4e2b1'),
    amount: 1,
    status: 'completed',
    customer_details: [
      {
        _id: ObjectId('60d5ec49f1b2c8b1f8e4e1a1'),
        name: 'Иван Иванов',
        address: { city: 'Москва', street: 'Ленина, 10' },
        interests: [ 'электроника', 'спорт' ]
      }
    ]
  },
  {
    _id: ObjectId('69fa49bbf908a8113644ba8a'),
    user_id: ObjectId('60d5ec49f1b2c8b1f8e4e1a2'),
    product_id: ObjectId('60d5ec49f1b2c8b1f8e4e2b2'),
    amount: 2,
    status: 'shipped',
    customer_details: [
      {
        _id: ObjectId('60d5ec49f1b2c8b1f8e4e1a2'),
        name: 'Анна Смирнова',
        address: { city: 'Санкт-Петербург', street: 'Невский, 5' },
        interests: [ 'книги', 'музыка' ]
      }
    ]
  }
]
```