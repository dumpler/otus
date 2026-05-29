# Домашнее задание 09

## Цель

Упаковать скрипт создания MySQL базы данных в Docker-контейнер

В задании используются:

- стартовый репозиторий `otus-mysql-docker`
- `docker-compose.yml`
- `init.sql`
- кастомный конфиг MySQL
- проверка контейнера через `mysql`
- тест sysbench

## Стартовый репозиторий

За основу взят репозиторий:

```text
https://github.com/aeuge/otus-mysql-docker
```

Из него использована структура:

- `docker-compose.yml`
- `init.sql`
- `custom.conf/my.cnf`

## Файлы

- `docker-compose.yml` - контейнер MySQL
- `init.sql` - создание базы `office_booking_mysql`, таблиц и тестовых данных
- `custom.conf/my.cnf` - пользовательские настройки MySQL

## Запуск MySQL

```bash
docker compose up -d
```

## Подключение

Через контейнер:

```bash
docker compose exec otusdb mysql -u root -p12345 office_booking_mysql
```

Через локальный mysql-клиент:

```bash
mysql -u root -p12345 --port=3309 --protocol=tcp office_booking_mysql
```

## Создание базы

В `init.sql` создается база:

```sql
CREATE DATABASE IF NOT EXISTS office_booking_mysql
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
```

Создаются таблицы:

- `departments`
- `employees`
- `offices`
- `workplaces`
- `bookings`

Таблицы используют `InnoDB`, первичные ключи, внешние ключи, уникальные ограничения и индексы для поиска бронирований

## Проверка данных

```bash
docker compose exec -T otusdb mysql -u root -p12345 office_booking_mysql -e "SHOW TABLES"
```

Ожидаемый результат:

```text
Tables_in_office_booking_mysql
bookings
departments
employees
offices
workplaces
```

Проверить тестовые бронирования:

```bash
docker compose exec -T otusdb mysql -u root -p12345 office_booking_mysql -e "SELECT e.email, w.code, b.starts_at, b.ends_at, b.status FROM bookings b JOIN employees e ON e.id = b.employee_id JOIN workplaces w ON w.id = b.workplace_id ORDER BY b.id"
```

Ожидаемый результат:

```text
email                       code   starts_at            ends_at              status
ivan.petrov@example.com     A-501  2026-06-01 09:00:00  2026-06-01 18:00:00  confirmed
maria.kuznetsova@example.com Q-501 2026-06-03 09:00:00  2026-06-03 18:00:00  confirmed
```

## Кастомный конфиг

В `custom.conf/my.cnf` добавлены настройки:

```ini
[mysqld]
default-authentication-plugin=mysql_native_password
innodb_buffer_pool_size=256M
innodb_log_file_size=128M
innodb_flush_log_at_trx_commit=1
max_connections=200
slow_query_log=ON
long_query_time=1
```

Проверить параметры:

```bash
docker compose exec -T otusdb mysql -u root -p12345 -e "SHOW VARIABLES WHERE Variable_name IN ('innodb_buffer_pool_size', 'innodb_log_file_size', 'max_connections', 'slow_query_log', 'long_query_time')"
```

## Sysbench

Подготовка данных:

```bash
sysbench oltp_read_write \
  --mysql-host=127.0.0.1 \
  --mysql-port=3309 \
  --mysql-user=root \
  --mysql-password=12345 \
  --mysql-db=office_booking_mysql \
  --tables=4 \
  --table-size=10000 \
  prepare
```

Запуск теста:

```bash
sysbench oltp_read_write \
  --mysql-host=127.0.0.1 \
  --mysql-port=3309 \
  --mysql-user=root \
  --mysql-password=12345 \
  --mysql-db=office_booking_mysql \
  --tables=4 \
  --table-size=10000 \
  --threads=2 \
  --time=10 \
  run
```

Очистка sysbench-таблиц:

```bash
sysbench oltp_read_write \
  --mysql-host=127.0.0.1 \
  --mysql-port=3309 \
  --mysql-user=root \
  --mysql-password=12345 \
  --mysql-db=office_booking_mysql \
  --tables=4 \
  cleanup
```

Результат теста:

```text
SQL statistics:
    queries performed:
        read:                            61852
        write:                           17672
        other:                           8836
        total:                           88360
    transactions:                        4418   (441.52 per sec.)
    queries:                             88360  (8830.46 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          10.0049s
    total number of events:              4418

Latency (ms):
         min:                                    3.12
         avg:                                    4.53
         max:                                   26.18
         95th percentile:                        6.21
         sum:                                19997.08
```

## Остановка

```bash
docker compose down
```

Удалить данные:

```bash
docker compose down -v
```
