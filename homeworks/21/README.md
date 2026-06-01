# Домашнее задание 21

## Цель

Развернуть MongoDB, заполнить данными, выполнить запросы на выборку и обновление

Данные адаптированы под выпускной проект `office_booking`

## Файлы

- `docker-compose.yml` - контейнер MongoDB
- `initdb/01_seed.js` - начальные данные
- `01_queries.js` - выборки, агрегация и обновление
- `02_indexes.js` - индексы и сравнение `explain`

## Запуск MongoDB

```bash
docker compose up -d
```

При первом запуске создается база:

```text
office_booking_mongo
```

Коллекции:

- `offices`
- `workplaces`
- `bookings`

## Запросы на выборку и обновление

```bash
docker compose exec -T mongodb mongosh < 01_queries.js
```

Скрипт выполняет:

- поиск активных рабочих мест с монитором
- поиск бронирований за период
- агрегацию количества бронирований по статусам
- обновление рабочего места `B-401`
- повторную выборку обновленного документа

## Индексы

```bash
docker compose exec -T mongodb mongosh < 02_indexes.js
```

Создаются индексы:

```javascript
db.bookings.createIndex({ workplace_code: 1, starts_at: 1 })
db.workplaces.createIndex({ office_code: 1, type: 1, is_active: 1 })
```

Первый индекс нужен для поиска бронирований конкретного рабочего места за период

Второй индекс нужен для поиска активных рабочих мест по офису и типу

## Сравнение производительности

До создания индекса запрос по `bookings` использует коллекционный просмотр

В `explain('executionStats')` это видно по признакам:

```text
totalDocsExamined больше totalKeysExamined
```

После создания индекса используется ключ:

```text
workplace_code_1_starts_at_1
```

И количество просмотренных документов уменьшается до минимально необходимого

## Остановка

```bash
docker compose down -v
```
