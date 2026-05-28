# Домашнее задание 04

## Цель

Реализовать спроектированную схему проекта в PostgreSQL с помощью DDL

В задании создаются:

- база данных
- роли
- табличные пространства
- схемы данных
- таблицы проекта с распределением по схемам и табличным пространствам

## Файлы

- `docker-compose.yml` - PostgreSQL и pgAdmin для выполнения задания
- `01_cluster.sql` - роли, табличные пространства и база данных
- `02_schema.sql` - схемы, таблицы и права доступа

## Запуск PostgreSQL

Запустить контейнеры:

```bash
docker compose up -d
```

Проверить состояние:

```bash
docker compose ps
```

## Подготовка каталогов для tablespace

PostgreSQL требует, чтобы каталоги для табличных пространств существовали на сервере до выполнения `CREATE TABLESPACE`

Создать каталоги внутри контейнера:

```bash
docker compose exec -u root postgres mkdir -p /var/lib/postgresql/tablespaces/office_core
docker compose exec -u root postgres mkdir -p /var/lib/postgresql/tablespaces/office_booking
docker compose exec -u root postgres mkdir -p /var/lib/postgresql/tablespaces/office_audit
docker compose exec -u root postgres chown -R postgres:postgres /var/lib/postgresql/tablespaces
```

## Создание ролей, tablespace и базы данных

Скрипт выполняется в базе `postgres` пользователем с правами суперпользователя

```bash
docker compose exec -T postgres psql -U postgres -d postgres -v ON_ERROR_STOP=1 < 01_cluster.sql
```

В результате создаются роли:

- `office_booking_owner` - владелец объектов базы
- `office_booking_app` - пользователь приложения
- `office_booking_readonly` - пользователь только для чтения

Создаются табличные пространства:

- `office_core_ts` - справочники, сотрудники, офисная структура и планы
- `office_booking_ts` - бронирования, статусы, причины отмены и периоды недоступности
- `office_audit_ts` - журнал аудита

Создается база данных:

- `office_booking`

## Создание схем и таблиц

Второй скрипт выполняется в созданной базе `office_booking`

```bash
docker compose exec -T postgres psql -U postgres -d office_booking -v ON_ERROR_STOP=1 < 02_schema.sql
```

Создаются схемы:

- `office` - сотрудники, роли, офисы, этажи, зоны, рабочие места и планы
- `booking` - бронирования, статусы и история статусов
- `audit` - журнал изменений

## Распределение таблиц по tablespace

### office_core_ts

В это табличное пространство помещены справочники и офисная структура:

- `office.departments`
- `office.employees`
- `office.roles`
- `office.employee_roles`
- `office.offices`
- `office.floors`
- `office.zones`
- `office.workplace_types`
- `office.workplaces`
- `office.floor_plans`
- `office.workplace_map_points`

### office_booking_ts

В это табличное пространство помещены операционные данные бронирования:

- `office.workplace_unavailability`
- `booking.booking_statuses`
- `booking.cancellation_reasons`
- `booking.bookings`
- `booking.booking_status_history`

### office_audit_ts

В это табличное пространство помещен журнал аудита:

- `audit.change_log`

## Проверка

Проверить базу данных:

```sql
SELECT datname
FROM pg_database
WHERE datname = 'office_booking';
```

Проверить роли:

```sql
SELECT rolname
FROM pg_roles
WHERE rolname LIKE 'office_booking_%'
ORDER BY rolname;
```

Проверить табличные пространства:

```sql
SELECT spcname
FROM pg_tablespace
WHERE spcname LIKE 'office_%'
ORDER BY spcname;
```

Проверить распределение таблиц:

```sql
SELECT
    schemaname,
    tablename,
    tablespace
FROM pg_tables
WHERE schemaname IN ('office', 'booking', 'audit')
ORDER BY schemaname, tablename;
```

## Остановка

Остановить контейнеры без удаления данных:

```bash
docker compose down
```

Остановить контейнеры и удалить volumes:

```bash
docker compose down -v
```
