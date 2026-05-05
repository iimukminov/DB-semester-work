```bash
docker exec -it neo4j cypher-shell -u neo4j -p password123
```

**ДЗ**

Задать структуру:

```
CREATE (alex:User {name: "Alex"}),
       (maria:User {name: "Maria"}),
       (john:User {name: "John"});
             
CREATE (inception:Movie {title: "Inception"}),
       (matrix:Movie {title: "The Matrix"});
             
MATCH (a:User {name: "Alex"}), (m:User {name: "Maria"})
CREATE (a)-[:FRIENDS]->(m);
             
MATCH (a:User {name: "Alex"}), (i:Movie {title: "Inception"})
CREATE (a)-[:WATCHED {rating: 5}]->(i);
```

### Часть 1. Выполнение запросов на Cypher (Neo4j)

* **1. Найти всех друзей Алекса:**
  Запрос ищет узел пользователя с именем "Alex" и проходит по связи `FRIENDS` к другим узлам типа `User`.
  ```cypher
  MATCH (alex:User {name: "Alex"})-[:FRIENDS]-(friend:User)
  RETURN friend.name AS Friend;
  ```

```text
neo4j@neo4j>     MATCH (alex:User {name: "Alex"})-[:FRIENDS]-(friend:User)
                 RETURN friend.name AS Friend;
+---------+
| Friend  |
+---------+
| "Maria" |
+---------+

1 row
ready to start consuming query after 182 ms, results consumed after another 4 ms
```

*   **2. Найти фильмы, которые смотрели друзья Алекса, но не смотрел сам Алекс:**
    Запрос строит путь от Алекса к его друзьям, а от них — к фильмам. Затем с помощью условия `WHERE NOT` отсекаются фильмы, с которыми у Алекса уже есть прямая связь `WATCHED`.
    ```cypher
    MATCH (alex:User {name: "Alex"})-[:FRIENDS]-(friend:User)-[:WATCHED]->(movie:Movie)
    WHERE NOT (alex)-[:WATCHED]->(movie)
    RETURN DISTINCT movie.title AS RecommendedMovie;
    ```

```text
neo4j@neo4j>     MATCH (alex:User {name: "Alex"})-[:FRIENDS]-(friend:User)-[:WATCHED]->(movie:Movie)
                 WHERE NOT (alex)-[:WATCHED]->(movie)
                 RETURN DISTINCT movie.title AS RecommendedMovie;
+------------------+
| RecommendedMovie |
+------------------+
+------------------+

0 rows
ready to start consuming query after 443 ms, results consumed after another 13 ms
```
---

### Часть 2. Аналогичный запрос на SQL

Для перевода этой логики на SQL нам нужно представить классическую реляционную структуру из 4 таблиц: `users`, `movies` и двух связующих таблиц: `friends` (user_id, friend_id) и `watched` (user_id, movie_id).

*   **SQL-запрос для поиска рекомендованных фильмов (смотрели друзья, не смотрел Алекс):**
    ```sql
    SELECT DISTINCT m.title
    FROM users u
    -- 1. Находим друзей Алекса
    JOIN friends f ON u.id = f.user_id
    -- 2. Находим фильмы, которые смотрели эти друзья
    JOIN watched w_friend ON f.friend_id = w_friend.user_id
    JOIN movies m ON w_friend.movie_id = m.id
    WHERE u.name = 'Alex'
      -- 3. Исключаем фильмы, которые Алекс уже посмотрел сам
      AND NOT EXISTS (
          SELECT 1 
          FROM watched w_alex 
          WHERE w_alex.user_id = u.id 
            AND w_alex.movie_id = m.id
      );
    ```

---

### Часть 3. Сравнение сложности запросов (Cypher vs SQL)

Сравнение двух подходов отлично иллюстрирует, почему для рекомендательных систем выбирают графовые базы данных. Вот основные отличия по пунктам:

*   **1. Синтаксис и читаемость (Интуитивность):**
    *   **Cypher:** Использует визуальный синтаксис (ASCII-арт `()-[]->()`), который повторяет рисунок графа на доске. Мы читаем запрос слева направо как предложение: "Алекс -> друг -> фильм".
    *   **SQL:** Требует создания громоздкой конструкции из трех `JOIN` и одного вложенного подзапроса (`NOT EXISTS`). Логика «размазана» по тексту запроса, и при добавлении новых условий (например, "друзья друзей") запрос станет нечитаемым.
*   **2. Производительность (Глубина связей):**
    *   **Cypher (Neo4j):** Использует принцип *Index-Free Adjacency*. Узлы физически хранят прямые указатели на своих соседей. Переход по связи (от друга к фильму) занимает константное время $O(1)$ и не зависит от общего объема данных в базе.
    *   **SQL:** Вычисляет связи "на лету" во время выполнения запроса. Каждый `JOIN` — это поиск по индексу B-Tree или полное сканирование таблицы. При увеличении количества связей и пользователей (миллионы строк в таблице `friends`) такие запросы начинают критически тормозить.
*   **3. Гибкость схемы (Модель данных):**
    *   **Cypher (Neo4j):** Бессхемный (schema-less) подход для связей. Чтобы добавить свойство `rating: 5` к связи, мы просто пишем его в `CREATE`. Если завтра мы захотим добавить связь `[:LIKED]`, нам не нужно менять структуру базы.
    *   **SQL:** Жесткая схема (rigid schema). Для добавления рейтинга или нового типа отношений потребуется писать скрипты миграций (`ALTER TABLE`), создавать новые колонки или отдельные связующие таблицы, что в больших проектах является сложной и опасной операцией.