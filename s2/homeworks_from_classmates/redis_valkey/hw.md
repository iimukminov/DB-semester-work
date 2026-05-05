```bash
docker exec -it redis-hw redis-cli --raw
```

### Задание 1. Hash — данные о студентах
Создаем записи для трех студентов и проверяем результат для первого.

```bash
HSET student:1 name "Иван Иванов" group "CS-101" gpa 3.8
HSET student:2 name "Анна Смирнова" group "CS-101" gpa 4.5
HSET student:3 name "Петр Петров" group "CS-102" gpa 3.2

HGETALL student:1
```

```text
127.0.0.1:6379> HGETALL student:1
name
Иван Иванов
group
CS-101
gpa
3.8
```

### Задание 2. Sorted Set — лидерборд по GPA
Создаем рейтинг и выводим его по убыванию балла.

```bash
ZADD gpa_leaderboard 3.8 "Иван Иванов" 4.5 "Анна Смирнова" 3.2 "Петр Петров"

ZREVRANGE gpa_leaderboard 0 2 WITHSCORES
```

```text
127.0.0.1:6379> ZREVRANGE gpa_leaderboard 0 2 WITHSCORES
Анна Смирнова
4.5
Иван Иванов
3.8
Петр Петров
3.2
```

### Задание 3. List — очередь задач
Добавляем задачи в конец очереди и забираем первые три.

```bash
RPUSH task_queue "task_1" "task_2" "task_3" "task_4" "task_5"

LPOP task_queue 3
```

```text
127.0.0.1:6379> LPOP task_queue 3
task_1
task_2
task_3
```

### Задание 4. TTL — время жизни ключа
Задаем временный ключ и проверяем его удаление.

```bash
SET session:123 "active" EX 10
TTL session:123
GET session:123
```

```text
127.0.0.1:6379> SET session:123 "active" EX 10
OK
127.0.0.1:6379> TTL session:123
10
127.0.0.1:6379> TTL session:123
2
127.0.0.1:6379> GET session:123
   (пусто типо)
```

### Задание 5. Транзакция MULTI/EXEC
Смоделируйте «перевод» 1 балла GPA от студента 1 к студенту 2

```bash
MULTI
HINCRBYFLOAT student:1 gpa -1.0
HINCRBYFLOAT student:2 gpa 1.0
EXEC
```

```text
127.0.0.1:6379> MULTI
OK
127.0.0.1:6379(TX)> HINCRBYFLOAT student:1 gpa -1.0
QUEUED
127.0.0.1:6379(TX)> HINCRBYFLOAT student:2 gpa 1.0
QUEUED
127.0.0.1:6379(TX)> EXEC
2.8
5.5
```

### Задание 6. Pub/Sub (Бонус)
Откройте **два** терминала с `redis-cli`.

**Терминал 1** — подписчик:

```bash
docker exec -it redis-hw redis-cli
SUBSCRIBE news
```

**Терминал 2** — издатель:

```bash
docker exec -it redis-hw redis-cli
PUBLISH news "Hello from Redis!"
PUBLISH news "Second message"
```

```text
127.0.0.1:6379> SUBSCRIBE news
1) "subscribe"
2) "news"
3) (integer) 1

1) "message"
2) "news"
3) "Hello from Redis!"

1) "message"
2) "news"
3) "Second message"
```

После ввода команд во втором терминале, сообщения моментально отображаются в первом