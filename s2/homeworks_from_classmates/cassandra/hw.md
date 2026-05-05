### Задание 1: Инициализация БД с репликацией

1. Сохраните предоставленный вами текст конфигурации в файл `docker-compose.yml`.
2. Откройте терминал в папке с этим файлом и запустите кластер в фоновом режиме:
   ```bash
   docker compose up -d
   ```
   *Cassandra довольно «тяжелая» и долго запускается. Подождите пару минут. Вы можете проверить статус нод
   командой `docker exec -it cassandra-node1 nodetool status`. Как только обе ноды получат статус `UN` (Up/Normal),
   можно продолжать.*
3. Подключитесь к консоли Cassandra (`cqlsh`) на первой ноде:
   ```bash
   docker exec -it cassandra-node1 cqlsh
   ```
4. Создайте Keyspace `university` с фактором репликации **2** (данные будут дублироваться на обе ноды):
   ```cql
   CREATE KEYSPACE university WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 2};
   ```

---

### Задание 2: Создание таблицы и данных

В Cassandra первичный ключ состоит из двух частей. **Partition Key** (`student_id`) определяет, на каком узле (сервере)
будут лежать данные, а **Clustering Key** (`created_at`) определяет, как данные будут отсортированы физически на диске
внутри этого узла.

1. Переключитесь на созданный Keyspace и создайте таблицу:
   ```cql
   USE university;

   CREATE TABLE student_grades (
       student_id uuid,
       created_at timestamp,
       subject text,
       grade int,
       PRIMARY KEY ((student_id), created_at)
   );
   ```
2. Выполним вставку данных.
   *Важное замечание: Если мы просто вызовем `uuid()` в каждом `INSERT`, база сгенерирует 4 абсолютно разных ID (то есть
   у нас получится 4 разных студента по 1 оценке). Чтобы строго выполнить условие «по 2 вставки для двух разных
   студентов», мы сгенерируем два UUID вручную (или скопируем их). В реальном коде приложения этот ID генерируется на
   стороне бэкенда.*

   Вставьте эти данные в `cqlsh`:
   ```cql
   -- Оценки первого студента
   INSERT INTO student_grades (student_id, created_at, subject, grade) 
   VALUES (11111111-1111-1111-1111-111111111111, '2023-10-01 10:00:00', 'Math', 5);
   
   INSERT INTO student_grades (student_id, created_at, subject, grade) 
   VALUES (11111111-1111-1111-1111-111111111111, '2023-10-02 10:00:00', 'Physics', 4);

   -- Оценки второго студента
   INSERT INTO student_grades (student_id, created_at, subject, grade) 
   VALUES (22222222-2222-2222-2222-222222222222, '2023-10-01 11:00:00', 'Math', 3);
   
   INSERT INTO student_grades (student_id, created_at, subject, grade) 
   VALUES (22222222-2222-2222-2222-222222222222, '2023-10-02 11:00:00', 'Physics', 5);
   ```

---

### Задание 3: Проверка распределения данных (Partitioning)

1. Посмотрим UUID наших студентов в таблице (не выходя из `cqlsh`):
   ```cql
   SELECT student_id FROM student_grades;
   ```

   ```text
   cqlsh:university> SELECT student_id FROM student_grades;
   
   student_id
   --------------------------------------
   22222222-2222-2222-2222-222222222222
   22222222-2222-2222-2222-222222222222
   11111111-1111-1111-1111-111111111111
   11111111-1111-1111-1111-111111111111
   
   (4 rows)
   ```

2. Выйдите из `cqlsh` (набрав `exit` или нажав `Ctrl+D`), чтобы вернуться в обычный терминал.
3. Выполните команду `nodetool getendpoints`, подставив UUID:
   ```bash
   docker exec -it cassandra-node1 nodetool getendpoints university student_grades 11111111-1111-1111-1111-111111111111
   ```
   ```text
   PS C:\Users\ilyam\IdeaProjects\DB-semester-work\homeworks_from_classmates\cassandra> docker exec -it cassandra-node1 nodetool getendpoints university student_grades 11111111-1111-1111-1111-111111111111
   172.23.0.2
   172.23.0.3
   ```
   
   **Результат:** Вы увидите в выводе **два IP-адреса**. Это адреса `node1` и `node2`. Так как мы задали
   `replication_factor: 2`, Cassandra честно положила копию этих данных на обе ноды в кластере для отказоустойчивости.

---

### Задание 4: Работа с фильтрацией

Снова зайдите в `cqlsh` (`docker exec -it cassandra-node1 cqlsh`) и выберите базу (`USE university;`).

1. **Попытка поиска по предмету:**
   ```cql
   SELECT * FROM student_grades WHERE subject = 'Math';
   ```
   ```text
   InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
   ```
   
   **Результат (Ошибка):** Вы получите ошибку вида
   `InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"`.
   *Почему?* Cassandra спроектирована для работы с петабайтами данных. Поиск по неключевому полю (`subject`) означает,
   что базе пришлось бы обойти все ноды и просканировать каждую строку на жестких дисках (Full Scan). Это убило бы
   производительность кластера, поэтому такое действие запрещено по умолчанию.

2. **Запрос с ALLOW FILTERING:**
   ```cql
   SELECT * FROM student_grades WHERE subject = 'Math' ALLOW FILTERING;
   ```
   ```text
   cqlsh:university> SELECT * FROM student_grades WHERE subject = 'Math' ALLOW FILTERING;

   student_id                           | created_at                      | grade | subject
   --------------------------------------+---------------------------------+-------+---------
   22222222-2222-2222-2222-222222222222 | 2023-10-01 11:00:00.000000+0000 |     3 |    Math
   11111111-1111-1111-1111-111111111111 | 2023-10-01 10:00:00.000000+0000 |     5 |    Math
   
   (2 rows)
   ```
   
**Результат:** Теперь запрос отработает успешно, и вы увидите все оценки по математике. Командой `ALLOW FILTERING` вы
берете ответственность на себя и говорите базе: «Я знаю, что это медленно и сканирует весь кластер, но мне очень нужны
эти данные».

В реальных рабочих проектах использовать `ALLOW FILTERING` крайне не рекомендуется. Если вам нужно часто искать по
предмету, в Cassandra принято создавать отдельные таблицы-индексы (например, таблицу `grades_by_subject` с Partition
Key = `subject`).