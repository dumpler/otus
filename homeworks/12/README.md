# Домашнее задание 12

## Цель

Заполнить MySQL-проект данными через хранимую процедуру с транзакцией и через загрузку CSV

Выполнены обе части:

- пример транзакции из проекта с изменением нескольких таблиц
- загрузка CSV через `LOAD DATA`
- загрузка CSV через `mysqlimport`

## Файлы

- `docker-compose.yml` - MySQL-контейнер
- `initdb/01_office_booking_transactions.sql` - база проекта и процедура `create_confirmed_booking`
- `initdb/02_load_data_demo.sql` - база для загрузки CSV
- `01_transaction_example.sql` - вызов процедуры и проверка измененных таблиц
- `02_load_data.sql` - загрузка `users.csv` через `LOAD DATA`
- `03_prepare_mysqlimport.sql` - очистка таблицы перед `mysqlimport`
- `users.csv` - исходный CSV
- `mysql-files/users.csv` - копия CSV, смонтированная в `/var/lib/mysql-files`

## Запуск MySQL

```bash
docker compose up -d
```

В `docker-compose.yml` задан параметр:

```yaml
command:
  - --secure-file-priv=/var/lib/mysql-files
```

Он разрешает серверной команде `LOAD DATA INFILE` читать файлы из `/var/lib/mysql-files`

## Часть 1. Транзакция проекта

Пример транзакции: сотрудник бронирует рабочее место

В рамках одной процедуры нужно:

- проверить активность сотрудника
- проверить активность рабочего места
- проверить отсутствие пересекающегося подтвержденного бронирования
- создать запись в `bookings`
- записать изменение статуса в `booking_status_history`
- обновить `workplaces.last_booked_at`

Процедура:

```sql
CREATE PROCEDURE create_confirmed_booking(
    IN p_employee_id BIGINT UNSIGNED,
    IN p_workplace_id BIGINT UNSIGNED,
    IN p_starts_at DATETIME(6),
    IN p_ends_at DATETIME(6),
    IN p_comment VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    ...

    INSERT INTO bookings (...);
    INSERT INTO booking_status_history (...);

    UPDATE workplaces
    SET last_booked_at = CURRENT_TIMESTAMP(6)
    WHERE id = p_workplace_id;

    COMMIT;
END;
```

Запустить пример:

```bash
docker compose exec -T otusdb mysql --default-character-set=utf8mb4 -u root -p12345 < 01_transaction_example.sql
```

Ожидаемый результат:

- в `bookings` появляется подтвержденное бронирование
- в `booking_status_history` появляется запись истории
- в `workplaces.last_booked_at` обновляется время последнего бронирования

## Часть 2. LOAD DATA

Файл `users.csv`:

```text
admin@example.com,Москва
user@example.com,Волгоград
guest@example.com,\N
```

Таблица:

```sql
CREATE TABLE IF NOT EXISTS users (
    email VARCHAR(255) NOT NULL,
    city VARCHAR(64),
    PRIMARY KEY (email)
) ENGINE=InnoDB;
```

CSV монтируется в контейнер:

```yaml
- ./mysql-files:/var/lib/mysql-files:ro
```

Загрузка через `LOAD DATA`:

```sql
LOAD DATA
INFILE '/var/lib/mysql-files/users.csv'
INTO TABLE users
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
(email, city);
```

Запустить:

```bash
docker compose exec -T otusdb mysql --default-character-set=utf8mb4 -u root -p12345 < 02_load_data.sql
```

Ожидаемый результат:

```text
email              city
admin@example.com  Москва
guest@example.com  NULL
user@example.com   Волгоград
```

При проверке используется `--default-character-set=utf8mb4`, чтобы русские значения из CSV корректно отображались в консоли

## Задание со звездой. mysqlimport

Перед повторной загрузкой очистить таблицу:

```bash
docker compose exec -T otusdb mysql --default-character-set=utf8mb4 -u root -p12345 < 03_prepare_mysqlimport.sql
```

Загрузить тот же файл через `mysqlimport`:

```bash
docker compose exec -T otusdb mysqlimport \
  -u root \
  -p12345 \
  --default-character-set=utf8mb4 \
  --fields-terminated-by=, \
  load_data_demo \
  /var/lib/mysql-files/users.csv
```

Ожидаемый результат:

```text
load_data_demo.users: Records: 3  Deleted: 0  Skipped: 0  Warnings: 0
```

Проверить результат:

```bash
docker compose exec -T otusdb mysql --default-character-set=utf8mb4 -u root -p12345 load_data_demo -e "SELECT email, city FROM users ORDER BY email"
```

## Остановка

```bash
docker compose down
```

Удалить данные:

```bash
docker compose down -v
```
