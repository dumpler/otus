# Домашнее задание 17

## Цель

Проанализировать план выполнения сложного запроса и определить, где теряется время

Задание адаптировано под выпускной проект `office_booking`

Вместо товаров и заказов используются:

- офисы
- зоны
- рабочие места
- типы рабочих мест
- бронирования
- статусы бронирований

## Файлы

- `docker-compose.yml` - MySQL-контейнер
- `initdb/01_office_booking_profile.sql` - схема, тестовые данные и view со сложным запросом
- `01_explain_before.sql` - план до оптимизации
- `02_optimize.sql` - индексы и сбор статистики
- `03_explain_after.sql` - план после индексов
- `04_rewritten_query.sql` - переписанный вариант запроса с CTE

## Версия MySQL

Для этой работы используется образ `mysql:8.0`

При проверке был использован MySQL `8.0.46`

Это важно, потому что `@@explain_format`, `FORMAT=TREE` и `EXPLAIN ANALYZE` недоступны в старом образе `mysql:8.0.15`, который использовался в предыдущих домашних работах

Документация MySQL по `EXPLAIN`: https://dev.mysql.com/doc/refman/8.0/en/explain.html

## Запуск MySQL

```bash
docker compose up -d
```

## План до оптимизации

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 01_explain_before.sql
```

В скрипте строятся три представления плана:

```sql
SET @@explain_format = TRADITIONAL;

EXPLAIN
SELECT *
FROM v_zone_booking_profile;
```

```sql
EXPLAIN FORMAT=JSON
SELECT *
FROM v_zone_booking_profile;
```

```sql
SET @@explain_format = TREE;

EXPLAIN
SELECT *
FROM v_zone_booking_profile;
```

Дополнительно выполняется:

```sql
EXPLAIN ANALYZE
SELECT *
FROM v_zone_booking_profile;
```

## Анализ исходного плана

Сложный запрос находится во view `v_zone_booking_profile`

Он делает отчет по бронированиям за июнь 2026 года:

- группировка по офису
- группировка по зоне
- группировка по типу рабочего места
- подсчет активных рабочих мест
- подсчет бронирований
- подсчет подтвержденных бронирований
- подсчет забронированных часов
- подзапрос для количества подтвержденных бронирований по зоне
- `EXISTS` для проверки, что у рабочего места были активные бронирования

Главная проблема до оптимизации была в подзапросе `Select #4`

Фрагмент `EXPLAIN ANALYZE`:

```text
-> Select #4 (subquery in projection; dependent)
    -> Aggregate: count(0) (actual time=8.05..8.05 rows=1 loops=3548)
        -> Nested loop inner join (actual time=0.0309..8.02 rows=455 loops=3548)
            -> Filter (...) (actual time=0.0198..5.3 rows=2733 loops=3548)
                -> Table scan on b2 (actual time=0.00603..3.98 rows=12000 loops=3548)
```

Самое тяжелое место:

- таблица `bookings` в подзапросе `b2` читается полным сканированием
- сканирование выполняется `3548` раз
- в каждом цикле просматривается `12000` строк
- суммарно получается очень дорогой повторный просмотр одной и той же таблицы

Общее время до оптимизации:

```text
actual time=28804..28804
```

То есть около `28.8` секунды

Также в плане видны:

- `Using temporary`
- `Using filesort`
- материализация view
- зависимый подзапрос

## Оптимизация индексами

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 02_optimize.sql
```

Добавлены индексы:

```sql
CREATE INDEX idx_bookings_period_status_workplace
ON bookings (starts_at, status_id, workplace_id);
```

Нужен для поиска бронирований за период и по статусу

```sql
CREATE INDEX idx_bookings_workplace_period_status
ON bookings (workplace_id, starts_at, status_id);
```

Нужен для соединений от рабочего места к его бронированиям за период

```sql
CREATE INDEX idx_workplaces_active_zone_type
ON workplaces (is_active, zone_id, type_id);
```

Нужен для фильтра активных рабочих мест и группировки по зоне и типу

После создания индексов выполнено:

```sql
ANALYZE TABLE bookings;
ANALYZE TABLE workplaces;
```

Это обновляет статистику оптимизатора

## План после индексов

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 03_explain_after.sql
```

В плане появились новые индексы:

```text
b   ref  idx_bookings_workplace_period_status  Using index condition
b2  ref  idx_bookings_workplace_period_status  Using where; Using index
```

Фрагмент `EXPLAIN ANALYZE` после индексов:

```text
-> Select #4 (subquery in projection; dependent)
    -> Aggregate: count(0) (actual time=1.42..1.42 rows=1 loops=3548)
        -> Nested loop inner join (actual time=0.0577..1.39 rows=455 loops=3548)
            -> Covering index lookup on w2 using uq_workplaces_zone_code (zone_id=z.id)
            -> Covering index lookup on b2 using idx_bookings_workplace_period_status
```

Общее время после индексов:

```text
actual time=5122..5122
```

То есть около `5.1` секунды

Индексы сильно уменьшили стоимость доступа к `bookings`, но зависимый подзапрос все еще выполняется `3548` раз

Это осталось самым тяжелым местом

## Оптимизация формы запроса

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 04_rewritten_query.sql
```

В переписанном варианте подзапрос заменен на CTE `zone_confirmed`

Также проверка `EXISTS` заменена на CTE `booked_workplaces`

Смысл:

- сначала один раз считаем рабочие места с активными бронированиями
- сначала один раз считаем подтвержденные бронирования по зонам
- потом присоединяем готовые наборы к основному отчету

Фрагмент `EXPLAIN ANALYZE`:

```text
-> Materialize CTE zone_confirmed (actual time=4.37..4.37 rows=6 loops=1)
-> Covering index range scan on b2 using idx_bookings_period_status_workplace
```

Общее время переписанного запроса:

```text
actual time=78.1..78.1
```

То есть около `78` мс

## Сравнение

| Вариант | Время |
| --- | ---: |
| До оптимизации | 28.8 с |
| После индексов и `ANALYZE TABLE` | 5.1 с |
| После переписывания запроса через CTE | 78 мс |

## Вывод

Основная потеря времени была не в большом количестве `JOIN` само по себе, а в подзапросе, который много раз перечитывал `bookings`

Индексы ускорили доступ к данным, но не убрали повторное выполнение подзапроса

Самый сильный эффект дала замена подзапроса на предварительную агрегацию через CTE

## Остановка

```bash
docker compose down
```

Удалить данные:

```bash
docker compose down -v
```
