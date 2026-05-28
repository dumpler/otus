# Домашнее задание 06

## Цель

Создать индексы в PostgreSQL для базы `office_booking`, проверить их использование через `EXPLAIN` и описать назначение каждого индекса

В задании используются:

- обычный B-tree индекс
- составной B-tree индекс
- GIN индекс для полнотекстового поиска
- индекс на поле с функцией
- частичный индекс
- `EXPLAIN` для проверки плана выполнения

## Файлы

- `docker-compose.yml` - PostgreSQL и pgAdmin для выполнения задания
- `01_schema.sql` - схема базы
- `02_seed.sql` - тестовые данные
- `03_indexes.sql` - индексы и запросы с `EXPLAIN`

## Запуск PostgreSQL

```bash
docker compose up -d
```

## Подготовка базы

Создать схемы и таблицы:

```bash
docker compose exec -T postgres psql -U postgres -d office_booking -v ON_ERROR_STOP=1 < 01_schema.sql
```

Добавить тестовые данные:

```bash
docker compose exec -T postgres psql -U postgres -d office_booking -v ON_ERROR_STOP=1 < 02_seed.sql
```

Создать индексы и вывести планы запросов:

```bash
docker compose exec -T postgres psql -U postgres -d office_booking -v ON_ERROR_STOP=1 < 03_indexes.sql
```

## Тестовые данные

В seed добавлены данные через `generate_series`, чтобы планировщик PostgreSQL мог выбрать индексные планы на заметном объеме строк

Создаются:

- 5000 сотрудников
- 5000 рабочих мест
- 30000 бронирований

Без такого объема PostgreSQL часто выбирает `Seq Scan`, потому что для маленьких таблиц последовательное чтение дешевле индексного доступа

## Индекс по сотруднику

Индекс:

```sql
CREATE INDEX idx_bookings_employee_id
ON booking.bookings (employee_id);
```

Комментарий:

```sql
COMMENT ON INDEX booking.idx_bookings_employee_id IS 'Ускоряет поиск бронирований конкретного сотрудника';
```

Индекс нужен для сценария просмотра бронирований конкретного сотрудника

Запрос:

```sql
EXPLAIN (COSTS OFF)
SELECT
    id,
    workplace_id,
    booked_period
FROM booking.bookings
WHERE employee_id = 42;
```

Результат `EXPLAIN`:

```text
Bitmap Heap Scan on bookings
  Recheck Cond: (employee_id = 42)
  ->  Bitmap Index Scan on idx_bookings_employee_id
        Index Cond: (employee_id = 42)
```

## Составной индекс

Индекс:

```sql
CREATE INDEX idx_bookings_workplace_status_created
ON booking.bookings (workplace_id, status_id, created_at DESC);
```

Комментарий:

```sql
COMMENT ON INDEX booking.idx_bookings_workplace_status_created IS 'Ускоряет поиск последних бронирований рабочего места по статусу';
```

Индекс нужен для поиска последних активных бронирований по рабочему месту и статусу

Поля стоят в порядке фильтрации и сортировки:

- `workplace_id` - выбор рабочего места
- `status_id` - выбор статуса
- `created_at DESC` - выдача последних записей без дополнительной сортировки

Запрос:

```sql
EXPLAIN (COSTS OFF)
SELECT
    id,
    employee_id,
    created_at
FROM booking.bookings
WHERE workplace_id = 15
  AND status_id = 2
ORDER BY created_at DESC
LIMIT 10;
```

Результат `EXPLAIN`:

```text
Limit
  ->  Sort
        Sort Key: created_at DESC
        ->  Bitmap Heap Scan on bookings
              Recheck Cond: ((workplace_id = 15) AND (status_id = 2))
              ->  Bitmap Index Scan on idx_bookings_workplace_status_created
                    Index Cond: ((workplace_id = 15) AND (status_id = 2))
```

## Полнотекстовый индекс

Индекс:

```sql
CREATE INDEX idx_bookings_comment_fts
ON booking.bookings
USING GIN (to_tsvector('english', coalesce(comment, '')));
```

Комментарий:

```sql
COMMENT ON INDEX booking.idx_bookings_comment_fts IS 'Ускоряет полнотекстовый поиск по комментариям к бронированиям';
```

Индекс нужен для поиска по тексту комментариев к бронированиям

Например можно найти бронирования, где пользователь указал потребность в тихом месте и мониторе

Запрос:

```sql
EXPLAIN (COSTS OFF)
SELECT
    id,
    comment
FROM booking.bookings
WHERE to_tsvector('english', coalesce(comment, '')) @@ plainto_tsquery('english', 'quiet monitor');
```

Результат `EXPLAIN`:

```text
Bitmap Heap Scan on bookings
  Recheck Cond: (to_tsvector('english'::regconfig, COALESCE(comment, ''::text)) @@ '''quiet'' & ''monitor'''::tsquery)
  ->  Bitmap Index Scan on idx_bookings_comment_fts
        Index Cond: (to_tsvector('english'::regconfig, COALESCE(comment, ''::text)) @@ '''quiet'' & ''monitor'''::tsquery)
```

## Индекс на поле с функцией

Индекс:

```sql
CREATE INDEX idx_employees_lower_email
ON office.employees (lower(email));
```

Комментарий:

```sql
COMMENT ON INDEX office.idx_employees_lower_email IS 'Ускоряет поиск сотрудника по email без учета регистра';
```

Индекс нужен для поиска сотрудника по email без учета регистра

Обычный индекс по `email` не помогает запросу с `lower(email)`, потому что в условии используется выражение

Запрос:

```sql
EXPLAIN (COSTS OFF)
SELECT
    id,
    email,
    last_name,
    first_name
FROM office.employees
WHERE lower(email) = lower('EMPLOYEE420@example.com');
```

Результат `EXPLAIN`:

```text
Index Scan using idx_employees_lower_email on employees
  Index Cond: (lower(email) = 'employee420@example.com'::text)
```

## Частичный индекс

Индекс:

```sql
CREATE INDEX idx_workplaces_active_monitor
ON office.workplaces (zone_id, code)
WHERE is_active = TRUE
  AND has_monitor = TRUE;
```

Комментарий:

```sql
COMMENT ON INDEX office.idx_workplaces_active_monitor IS 'Ускоряет поиск активных рабочих мест с монитором внутри зоны';
```

Индекс нужен для частого сценария выбора доступных рабочих мест с монитором

В индекс попадает только часть таблицы, поэтому он меньше полного индекса по тем же полям

Запрос:

```sql
EXPLAIN (COSTS OFF)
SELECT
    id,
    code,
    name
FROM office.workplaces
WHERE zone_id = 2
  AND is_active = TRUE
  AND has_monitor = TRUE
ORDER BY code;
```

Результат `EXPLAIN`:

```text
Sort
  Sort Key: code
  ->  Bitmap Heap Scan on workplaces
        Recheck Cond: ((zone_id = 2) AND is_active AND has_monitor)
        ->  Bitmap Index Scan on idx_workplaces_active_monitor
              Index Cond: (zone_id = 2)
```

## Что делали

Сначала были определены основные сценарии чтения:

- просмотр бронирований сотрудника
- просмотр последних бронирований рабочего места
- поиск по комментариям к бронированиям
- поиск сотрудника по email без учета регистра
- подбор активных рабочих мест с монитором

Для каждого сценария выбран отдельный тип индекса

После создания индексов выполнен `ANALYZE`, чтобы планировщик получил актуальную статистику

Затем каждый запрос был проверен через `EXPLAIN (COSTS OFF)`

## Проблемы

На маленьких таблицах PostgreSQL выбирал `Seq Scan`, потому что последовательное чтение нескольких строк дешевле обращения к индексу

Поэтому в `02_seed.sql` добавлен больший набор тестовых данных через `generate_series`

Для полнотекстового поиска важно, чтобы выражение в запросе совпадало с выражением в индексе

Если индекс создан по `to_tsvector('english', coalesce(comment, ''))`, то в `WHERE` нужно использовать то же выражение

Для составного индекса PostgreSQL использовал сам индекс для отбора строк по `workplace_id` и `status_id`, но оставил отдельную сортировку по `created_at`

Это нормальный выбор планировщика для текущих тестовых данных, потому что он посчитал `Bitmap Index Scan` дешевле прямого прохода по индексу в порядке `created_at`

## Остановка

```bash
docker compose down
```

Удалить данные:

```bash
docker compose down -v
```
