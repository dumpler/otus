# Домашнее задание 16

## Цель

Создать пользователей, хранимые процедуры и триггеры в MySQL

Задание адаптировано под выпускной проект

Вместо товаров, категорий, производителей и заказов используются сущности `office_booking`:

- рабочие места
- офисы
- зоны
- типы рабочих мест
- бронирования
- статусы бронирований

## Файлы

- `docker-compose.yml` - MySQL-контейнер
- `initdb/01_office_booking_routines.sql` - схема и тестовые данные
- `01_create_users.sql` - пользователи `client` и `manager`
- `02_create_procedures_and_triggers.sql` - процедуры, триггеры и выдача прав
- `03_call_as_client.sql` - проверка процедуры клиента
- `04_call_as_manager.sql` - проверка процедуры менеджера
- `05_check_triggers.sql` - проверка audit-триггера

## Запуск MySQL

```bash
docker compose up -d
```

## Создание пользователей

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 01_create_users.sql
```

Создаются пользователи:

- `client`
- `manager`

## Создание процедур и триггеров

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 02_create_procedures_and_triggers.sql
```

## Процедура для клиента

В задании требуется процедура выборки товаров с фильтрами по категории, цене, производителю и дополнительным параметрам

В проекте вместо товаров используются рабочие места

Соответствие по смыслу:

- категория товара - тип рабочего места
- производитель - офис
- цена - вместимость рабочего места
- дополнительные параметры - монитор, активность, зона

Процедура:

```sql
CALL office_booking_routines.get_workplaces(
    'msk_main',
    NULL,
    'meeting_room',
    4,
    NULL,
    1,
    1,
    'seats',
    'desc',
    10,
    0
);
```

Параметры позволяют фильтровать:

- по офису
- по зоне
- по типу рабочего места
- по минимальной и максимальной вместимости
- по наличию монитора
- только активные рабочие места

Также передаются:

- поле сортировки
- направление сортировки
- лимит
- смещение для постраничной выдачи

Права на запуск выданы пользователю `client`

```sql
GRANT EXECUTE ON PROCEDURE office_booking_routines.get_workplaces TO 'client'@'%';
```

Проверка:

```bash
docker compose exec -T otusdb mysql -u client -pclient_pass < 03_call_as_client.sql
```

## Процедура для менеджера

В задании требуется процедура `get_orders` для отчета по продажам за период с разными уровнями группировки

В проекте вместо заказов и продаж используются бронирования рабочих мест

Процедура считает:

- количество бронирований
- количество подтвержденных бронирований
- количество отмененных бронирований
- забронированные часы

Можно выбрать шаг периода:

- `hour`
- `day`
- `week`

Можно выбрать группировку:

- `workplace`
- `zone`
- `office`
- `type`
- `status`
- `all`

Пример:

```sql
CALL office_booking_routines.get_orders(
    '2026-06-01 00:00:00',
    '2026-06-08 00:00:00',
    'day',
    'type'
);
```

Права на запуск выданы пользователю `manager`

```sql
GRANT EXECUTE ON PROCEDURE office_booking_routines.get_orders TO 'manager'@'%';
```

Проверка:

```bash
docker compose exec -T otusdb mysql -u manager -pmanager_pass < 04_call_as_manager.sql
```

## Триггеры

Добавлены два триггера для бронирований

`trg_bookings_before_insert_no_overlap` запрещает создать активное бронирование рабочего места на пересекающийся период

Так база защищает бизнес-правило, что одно рабочее место нельзя забронировать два раза на одно и то же время

`trg_bookings_after_insert_audit` пишет запись в `booking_audit` после создания бронирования

Проверка audit-триггера:

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 05_check_triggers.sql
```

Ожидаемый результат:

```text
booking_id  action_type  details
11          insert       Booking created for workplace 1
```

Проверка запрета пересекающихся бронирований:

```sql
INSERT INTO bookings (
    employee_id,
    workplace_id,
    status_id,
    starts_at,
    ends_at
)
VALUES (
    2,
    1,
    1,
    '2026-06-06 10:00:00.000000',
    '2026-06-06 12:00:00.000000'
);
```

Ожидаемая ошибка:

```text
ERROR 1644 (45000): Workplace already has active booking for this period
```

## Остановка

```bash
docker compose down
```

Удалить данные:

```bash
docker compose down -v
```
