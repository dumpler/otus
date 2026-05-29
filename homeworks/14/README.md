# Домашнее задание 14

## Цель

Пересмотреть индексы MySQL в проекте `office_booking` и реализовать полнотекстовый индекс

Задание адаптировано под выпускной проект

Вместо поиска по товарам используется поиск по рабочим местам:

- `workplaces.name`
- `workplaces.description`
- `workplaces.properties`

## Файлы

- `docker-compose.yml` - MySQL-контейнер
- `initdb/01_office_booking_indexes.sql` - схема и тестовые данные
- `01_before_indexes.sql` - `EXPLAIN` и выборки до добавления индексов
- `02_add_indexes.sql` - добавление индексов
- `03_after_indexes.sql` - `EXPLAIN` и выборки после добавления индексов

Тестовые строки в `initdb/01_office_booking_indexes.sql` создаются через рекурсивные CTE

## Запуск MySQL

```bash
docker compose up -d otusdb
```

## Проверка до индексов

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 01_before_indexes.sql
```

## Добавление индексов

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 02_add_indexes.sql
```

## Проверка после индексов

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 03_after_indexes.sql
```

## Анализ проекта

Основные сценарии чтения:

- найти бронирования конкретного рабочего места по статусу и дате
- найти активных сотрудников по отделу
- найти рабочие места по текстовым свойствам, названию и описанию

Для этих сценариев добавлены индексы:

```sql
CREATE INDEX idx_bookings_workplace_status_start
ON bookings (workplace_id, status_id, starts_at);
```

```sql
CREATE INDEX idx_employees_department_active
ON employees (department_id, is_active);
```

```sql
CREATE FULLTEXT INDEX ft_workplaces_search
ON workplaces (name, description, properties);
```

## Индекс по бронированиям

Запрос:

```sql
SELECT
    id,
    workplace_id,
    status_id,
    starts_at,
    ends_at
FROM bookings
FORCE INDEX (idx_bookings_workplace_status_start)
WHERE workplace_id = 42
  AND status_id = 2
  AND starts_at >= '2026-06-01 00:00:00'
ORDER BY starts_at
LIMIT 10;
```

До индекса MySQL использует отдельный внешний ключ по статусу и делает дополнительную фильтрацию с сортировкой

После индекса используется:

```text
type: range
key: idx_bookings_workplace_status_start
rows: 3
Extra: Using index condition
```

Индекс выбран в порядке условий:

- `workplace_id` - точный поиск по рабочему месту
- `status_id` - точный поиск по статусу
- `starts_at` - диапазон и сортировка по времени

В проверочном запросе после добавления индекса используется `FORCE INDEX`

На синтетических данных MySQL может выбрать существующий внешний ключ `fk_bookings_status`, потому что статистика считает такой план достаточно дешевым

Для задания важно показать план доступа через новый составной индекс

## Полнотекстовый индекс

До индекса поиск имитируется через `LIKE '%quiet%'`

```sql
SELECT
    id,
    code,
    name,
    description
FROM workplaces
WHERE name LIKE '%quiet%'
   OR description LIKE '%quiet%'
   OR properties LIKE '%quiet%'
ORDER BY id
LIMIT 10;
```

Такой запрос не использует обычный B-tree индекс, потому что шаблон начинается с `%`

После добавления `FULLTEXT` используется:

```sql
SELECT
    id,
    code,
    name,
    description,
    MATCH(name, description, properties) AGAINST('quiet focus monitor') AS relevance
FROM workplaces
WHERE MATCH(name, description, properties) AGAINST('quiet focus monitor')
ORDER BY relevance DESC
LIMIT 10;
```

Индекс:

```sql
CREATE FULLTEXT INDEX ft_workplaces_search
ON workplaces (name, description, properties);
```

Он покрывает название, описание и свойства рабочего места

Это соответствует смыслу задания про поиск по свойствам, названию и описанию

## Ожидаемое изменение EXPLAIN

Для бронирований после добавления индекса:

```text
key: idx_bookings_workplace_status_start
Extra: Using index condition
```

Для полнотекстового поиска после добавления индекса:

```text
type: fulltext
key: ft_workplaces_search
Extra: Using where; Ft_hints: sorted, limit = 10
```

## Проблемы

Основная проблема была в выборе плана для составного индекса

На небольшом искусственном наборе данных оптимизатор MySQL не всегда выбирает новый индекс сам, поэтому для демонстрации результата используется `FORCE INDEX`

Еще одна сложность была в генерации тестовых данных

В PostgreSQL для этого можно использовать `generate_series`, а в MySQL такого встроенного аналога нет

Поэтому тестовые строки создаются через рекурсивные CTE

## Остановка

```bash
docker compose down
```

Удалить данные:

```bash
docker compose down -v
```
