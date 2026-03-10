### 1-2. Моделирование обновления данных и изучение xmin, xmax, ctid, t_infomask

**Состояние строки до обновления**

```sql
SELECT t_xmin AS xmin, t_xmax AS xmax, t_ctid AS ctid, t_infomask
FROM heap_page_items(get_raw_page('marketplace.profession', 0));
```

**Результат:**

| xmin | xmax | ctid | t_infomask |
| :--- | :--- | :--- | :--- |
| 959 | 0 | (0,1) | 2050 |
| 959 | 0 | (0,2) | 2050 |

```sql
UPDATE marketplace.profession SET salary = 60000 WHERE profession_id = 1;
```

**Состояние строки после обновления**

```sql
SELECT t_xmin AS xmin, t_xmax AS xmax, t_ctid AS ctid, t_infomask
FROM heap_page_items(get_raw_page('marketplace.profession', 0))
WHERE t_infomask IS NOT NULL LIMIT 3;
```

**Результат:**

| xmin | xmax | ctid | t_infomask |
| :--- | :--- | :--- | :--- |
| 959 | 961 | (0,3) | 258 |
| 959 | 0 | (0,2) | 2050 |
| 961 | 0 | (0,3) | 10242 |


---


### 3. Видимость в разных транзакциях

**Терминал 1 (Начинает транзакцию и делает UPDATE):**

```sql
BEGIN;
UPDATE marketplace.profession SET salary = 99999 WHERE profession_id = 1;
SELECT xmin, xmax, ctid, salary FROM marketplace.profession WHERE profession_id = 1;
```

**Результат Терминала 1:**

| xmin | xmax | ctid | salary |
| :--- | :--- | :--- | :--- |
| 962 | 0 | (0,4) | 99999 |

**Терминал 2 (Пытается прочитать те же данные параллельно):**

```sql
BEGIN;
SELECT xmin, xmax, ctid, salary FROM marketplace.profession WHERE profession_id = 1;
```

**Результат Терминала 2:**

| xmin | xmax | ctid | salary |
| :--- | :--- | :--- | :--- |
| 961 | 962 | (0,3) | 60000 |

---

### 4. Deadlock

Имитация перекрестного обновления двух строк в двух сессиях.

1. **Окно 1:** `BEGIN; UPDATE marketplace.profession SET salary = 100 WHERE profession_id = 1;`
2. **Окно 2:** `BEGIN; UPDATE marketplace.profession SET salary = 200 WHERE profession_id = 2;`
3. **Окно 1:** `UPDATE marketplace.profession SET salary = 300 WHERE profession_id = 2;` *(Зависает, ждет Окно 2)*
4. **Окно 2:** `UPDATE marketplace.profession SET salary = 400 WHERE profession_id = 1;`

**Результат в логах PostgreSQL:**

```text
[40P01] ERROR: deadlock detected
Подробности: Process 3329 waits for ShareLock on transaction 963; blocked by process 3255.
Process 3255 waits for ShareLock on transaction 964; blocked by process 3329.
Где: while updating tuple (0,4) in relation "profession"
```

Анализ: PostgreSQL автоматически обнаружил цикличное ожидание (процесс 3329 ждал 3255, а 3255 ждал 3329) и принудительно прервал транзакцию в одном из окон с ошибкой 40P01, чтобы позволить второму процессу продолжить работу

---

### 5. Явные блокировки на уровне строк

**Окно 1 (Блокировка на обновление):**

```sql
BEGIN;
SELECT * FROM marketplace.profession WHERE profession_id = 1 FOR UPDATE;
```

**Окно 2:**

```sql
BEGIN;
SELECT * FROM marketplace.profession WHERE profession_id = 1 FOR SHARE;
```

---

### 6. Очистка данных (VACUUM)

```sql
VACUUM VERBOSE marketplace.profession;
```

**Результат:**

```text
vacuuming "marketplace_db.marketplace.profession"
pages: 0 removed, 1 remain, 1 scanned (100.00% of total)
tuples: 21 removed, 2 remain, 0 are dead but not yet removable
```
