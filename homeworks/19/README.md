# Домашнее задание 19

## Цель

Настроить асинхронную репликацию MySQL Source-Replica на GTID и проверить ее состояние

## Что сделано

Стенд состоит из двух серверов MySQL:

- `mysql-source` - источник данных
- `mysql-replica` - реплика

Реплика работает в режиме только для чтения:

```sql
SET GLOBAL read_only = ON;
SET GLOBAL super_read_only = ON;
```

Эти настройки включаются после начальной загрузки данных, потому что во время первого старта MySQL должен создать системные таблицы и пользователя `root`

Репликация настроена по GTID:

```ini
gtid_mode = ON
enforce_gtid_consistency = ON
```

Дополнительно настроена выборочная репликация:

```ini
replicate-ignore-db = office_booking_ignore
replicate-ignore-table = office_booking_replication.audit_log
```

## Файлы

- `docker-compose.yml` - два MySQL сервера
- `config/source.cnf` - настройки Source
- `config/replica.cnf` - настройки Replica
- `source-init/01_source.sql` - схема, данные и пользователь репликации
- `01_configure_replica.sql` - подключение реплики к source через GTID
- `02_source_changes.sql` - изменения на source после запуска репликации
- `03_check_source.sql` - проверка source
- `04_check_replica.sql` - проверка replica

## Запуск

```bash
docker compose up -d
```

## Начальная загрузка данных на Replica

Задание со звездочкой выполнено через начальную загрузку дампа с мастера на реплику

Перед импортом очищается GTID-состояние реплики, чтобы дамп с `--set-gtid-purged=ON` применился как начальная точка репликации

```bash
docker compose exec -T mysql-replica mysql -u root -p12345 -e "RESET MASTER"
```

```bash
docker compose exec -T mysql-source mysqldump \
  -u root -p12345 \
  --single-transaction \
  --set-gtid-purged=ON \
  --databases office_booking_replication \
| docker compose exec -T mysql-replica mysql -u root -p12345
```

## Запуск GTID-репликации

```bash
docker compose exec -T mysql-replica mysql -u root -p12345 < 01_configure_replica.sql
```

В конце скрипта реплика снова переводится в режим только для чтения

Внутри используется:

```sql
CHANGE REPLICATION SOURCE TO
    SOURCE_HOST = 'mysql-source',
    SOURCE_USER = 'repl',
    SOURCE_PASSWORD = 'repl_pass',
    SOURCE_AUTO_POSITION = 1,
    GET_SOURCE_PUBLIC_KEY = 1;
```

`SOURCE_AUTO_POSITION = 1` означает, что реплика использует GTID, а не binlog-файл

## Проверка read-only

```bash
docker compose exec -T mysql-replica mysql -u root -p12345 -e "SELECT @@read_only, @@super_read_only"
```

Ожидаемый результат:

```text
@@read_only  @@super_read_only
1            1
```

## Проверка работы репликации

Внести изменения на мастер:

```bash
docker compose exec -T mysql-source mysql -u root -p12345 < 02_source_changes.sql
```

Проверить мастер:

```bash
docker compose exec -T mysql-source mysql -u root -p12345 < 03_check_source.sql
```

Проверить реплику:

```bash
docker compose exec -T mysql-replica mysql -u root -p12345 < 04_check_replica.sql
```

В `SHOW REPLICA STATUS\G` важны поля:

```text
Replica_IO_Running: Yes
Replica_SQL_Running: Yes
Retrieved_Gtid_Set: ...
Executed_Gtid_Set: ...
Auto_Position: 1
```

## Выборочная репликация

На мастере после изменений:

```text
audit_log      2
ignored_events 2
```

На реплике:

```text
audit_log      1
```

Таблица `audit_log` не получает новую строку, потому что исключена правилом `replicate-ignore-table`

База `office_booking_ignore` не появляется на реплике, потому что исключена правилом `replicate-ignore-db`

## Остановка

```bash
docker compose down -v
```
