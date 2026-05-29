# Домашнее задание 10

## Цель

Проанализировать типы данных в MySQL-базе `office_booking_types`, уточнить типы для основных сущностей и добавить тип `JSON`

В задании используются:

- выбор типа ID
- `VARCHAR` вместо неограниченных строк
- `TINYINT UNSIGNED` и `SMALLINT UNSIGNED` для небольших справочников
- `BIGINT UNSIGNED` для внешних и быстро растущих ID
- `DATETIME(6)` для дат с точностью до микросекунд
- `JSON` для гибких атрибутов
- функциональные индексы по JSON-выражениям

## Файлы

- `docker-compose.yml` - MySQL-контейнер
- `init.sql` - схема, типы данных, JSON-поля и тестовые данные
- `02_json_queries.sql` - примеры выборки из JSON

## Запуск MySQL

```bash
docker compose up -d otusdb
```

## Проверка

Выполнить JSON-запросы:

```bash
docker compose exec -T otusdb mysql -u root -p12345 office_booking_types < 02_json_queries.sql
```

## Анализ ID

Для ID используются числовые суррогатные ключи

В проекте есть разные типы сущностей:

- сотрудники приходят из внешнего каталога
- бронирования создаются внутри системы и могут быстро расти
- справочники небольшие и меняются редко

Поэтому:

- `employees.id` - `BIGINT UNSIGNED`, потому что это внешний ID сотрудника
- `bookings.id` - `BIGINT UNSIGNED AUTO_INCREMENT`, потому что бронирований может быть много
- `departments.id`, `offices.id` - `SMALLINT UNSIGNED`, потому что отделов и офисов немного
- `workplace_types.id`, `booking_statuses.id` - `TINYINT UNSIGNED`, потому что это маленькие справочники

## Что изменилось по типам

### Коды

Было бы избыточно хранить коды как длинный текст

Используется:

```sql
code VARCHAR(32)
```

Коды отделов, офисов, типов рабочих мест и статусов короткие и участвуют в уникальных индексах

### Названия

Используется:

```sql
name VARCHAR(128)
```

Для названий отделов, офисов и рабочих мест не нужен большой `TEXT`

### Email

Используется:

```sql
email VARCHAR(255)
```

Email имеет естественное ограничение длины и участвует в уникальном индексе

### ФИО и должность

Используется:

```sql
last_name VARCHAR(100)
first_name VARCHAR(100)
middle_name VARCHAR(100)
position_name VARCHAR(150)
```

Эти поля имеют предсказуемую длину, поэтому `VARCHAR` точнее, чем `TEXT`

### Логические признаки

В MySQL для булевых значений фактически используется `TINYINT(1)`

```sql
is_active TINYINT(1)
has_monitor TINYINT(1)
has_docking_station TINYINT(1)
```

### Даты

Используется:

```sql
DATETIME(6)
```

`DATETIME(6)` хранит дату и время с микросекундами и не зависит от timezone сервера

Для бронирований используются отдельные поля:

```sql
starts_at DATETIME(6)
ends_at DATETIME(6)
```

В MySQL нет range-типа как `TSTZRANGE` в PostgreSQL, поэтому интервал бронирования хранится двумя колонками и защищается `CHECK (starts_at < ends_at)`

## JSON в структуре

Добавлены две JSON-колонки:

```sql
attributes JSON NOT NULL
```

в `workplaces`

```sql
client_context JSON NOT NULL
```

в `bookings`

Тип `JSON` в MySQL проверяет корректность JSON-документа при вставке

## Что хранить в JSON

В `workplaces.attributes` можно хранить гибкие свойства рабочего места:

- количество мониторов
- наличие док-станции
- раскладку клавиатуры
- признак доступности для маломобильных сотрудников
- теги вроде `quiet`, `window`, `focus`

В `bookings.client_context` можно хранить технический контекст бронирования:

- источник бронирования `web` или `mobile`
- версию приложения
- user agent
- фильтры, которые пользователь применил при выборе места

Эти данные полезны для аналитики, но не являются стабильными обязательными полями основной модели

## Примеры добавления JSON

```sql
INSERT IGNORE INTO workplaces (
    id,
    office_id,
    type_id,
    code,
    name,
    has_monitor,
    has_docking_station,
    attributes
)
VALUES
    (
        1,
        1,
        1,
        'A-501',
        'Desk A-501',
        1,
        1,
        JSON_OBJECT(
            'equipment',
            JSON_OBJECT('monitors', 2, 'dock', TRUE, 'keyboard', 'en'),
            'accessibility',
            JSON_OBJECT('wheelchair', TRUE),
            'tags',
            JSON_ARRAY('window', 'team')
        )
    );
```

```sql
INSERT IGNORE INTO bookings (
    id,
    employee_id,
    workplace_id,
    status_id,
    starts_at,
    ends_at,
    comment,
    client_context,
    created_by_employee_id
)
VALUES
    (
        1,
        1,
        1,
        2,
        '2026-06-01 09:00:00.000000',
        '2026-06-01 18:00:00.000000',
        'Regular office day',
        JSON_OBJECT('source', 'web', 'user_agent', 'Firefox', 'filters', JSON_OBJECT('monitor', TRUE, 'quiet', FALSE)),
        1
    );
```

## Примеры выборки JSON

Получить количество мониторов и раскладку клавиатуры:

```sql
SELECT
    code,
    name,
    JSON_UNQUOTE(JSON_EXTRACT(attributes, '$.equipment.monitors')) AS monitors_count,
    JSON_UNQUOTE(JSON_EXTRACT(attributes, '$.equipment.keyboard')) AS keyboard_layout
FROM workplaces
ORDER BY code;
```

Найти рабочие места с док-станцией:

```sql
SELECT
    code,
    name
FROM workplaces
WHERE JSON_CONTAINS(attributes, JSON_OBJECT('dock', TRUE), '$.equipment')
ORDER BY code;
```

Найти бронирования, где пользователь выбирал место с монитором:

```sql
SELECT
    b.id,
    e.email,
    JSON_UNQUOTE(JSON_EXTRACT(b.client_context, '$.source')) AS booking_source,
    JSON_UNQUOTE(JSON_EXTRACT(b.client_context, '$.filters.quiet')) AS quiet_filter
FROM bookings b
JOIN employees e ON e.id = b.employee_id
WHERE JSON_EXTRACT(b.client_context, '$.filters.monitor') = TRUE
ORDER BY b.id;
```

## Индексы по JSON

В MySQL можно индексировать выражения по JSON

```sql
KEY idx_workplaces_monitor_count ((CAST(JSON_UNQUOTE(JSON_EXTRACT(attributes, '$.equipment.monitors')) AS UNSIGNED)))
```

```sql
KEY idx_bookings_source ((CAST(JSON_UNQUOTE(JSON_EXTRACT(client_context, '$.source')) AS CHAR(32))))
```

Первый индекс помогает искать рабочие места по количеству мониторов

Второй индекс помогает анализировать бронирования по источнику создания

## Ожидаемый результат

```text
code	name	monitors_count	keyboard_layout
A-501	Desk A-501	2	en
Q-501	Focus room Q-501	1	NULL
```

```text
code	name
A-501	Desk A-501
Q-501	Focus room Q-501
```

```text
id	email	booking_source	quiet_filter
1	ivan.petrov@example.com	web	false
2	maria.kuznetsova@example.com	mobile	true
```

## Остановка

```bash
docker compose down
```

Удалить данные:

```bash
docker compose down -v
```
