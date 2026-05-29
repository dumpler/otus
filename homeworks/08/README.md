# Домашнее задание 08

## Цель

Настроить физическую и логическую репликацию PostgreSQL в docker compose

В задании используются:

- физическая streaming репликация
- физический слот репликации
- задержка применения WAL на реплике 5 минут
- логическая публикация
- логическая подписка
- проверка репликации через SQL запросы

## Стенд

В `docker-compose.yml` описаны три кластера PostgreSQL:

- `primary` - основной сервер
- `physical_replica` - физическая реплика основного сервера
- `logical_replica` - отдельный сервер для логической репликации

Порты:

- `5432` - primary
- `5433` - physical replica
- `5434` - logical replica

## Файлы

- `docker-compose.yml` - стенд из трех PostgreSQL-кластеров
- `primary-init/00_pg_hba.sh` - доступ пользователя `replicator` к replication-подключениям
- `primary-init/01_primary.sql` - пользователь репликации, физический слот, база, таблица, данные и публикация
- `logical-init/01_schema.sql` - таблица на логической реплике
- `scripts/physical-replica-entrypoint.sh` - инициализация физической реплики через `pg_basebackup`
- `02_create_subscription.sql` - создание логической подписки
- `03_check_replication.sql` - проверка слотов, физической репликации и добавление новых строк на primary
- `04_check_logical_replica.sql` - проверка данных на логической реплике

## Запуск стенда

```bash
docker compose up -d
```

Проверить контейнеры:

```bash
docker compose ps
```

## Физическая репликация

На primary создается пользователь для репликации:

```sql
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator';
```

В `pg_hba.conf` добавляется правило для replication-подключений:

```conf
host replication replicator all scram-sha-256
```

Также создается физический replication slot:

```sql
SELECT pg_create_physical_replication_slot('physical_replica_slot');
```

Физическая реплика инициализируется через `pg_basebackup`

```bash
pg_basebackup \
    -h "$PRIMARY_HOST" \
    -p "$PRIMARY_PORT" \
    -U "$REPLICATION_USER" \
    -D "$PGDATA" \
    -S "$REPLICATION_SLOT" \
    -R \
    --checkpoint=fast \
    --wal-method=stream
```

Ключ `-S physical_replica_slot` подключает реплику к созданному replication slot

Ключ `-R` записывает параметры подключения к primary в `postgresql.auto.conf`

Задержка применения WAL задается на физической реплике:

```conf
recovery_min_apply_delay = '5min'
```

Это означает, что реплика получает WAL от primary, но применяет изменения с задержкой 5 минут

## Проверка физической репликации

Проверить слоты на primary:

```bash
docker compose exec -T primary psql -U postgres -d postgres -c "SELECT slot_name, slot_type, active FROM pg_replication_slots ORDER BY slot_name"
```

Ожидаемый результат:

```text
       slot_name       | slot_type | active
-----------------------+-----------+--------
 physical_replica_slot | physical  | t
```

Проверить подключенную физическую реплику:

```bash
docker compose exec -T primary psql -U postgres -d postgres -c "SELECT application_name, state, sync_state, replay_lag FROM pg_stat_replication ORDER BY application_name"
```

Ожидаемый результат:

```text
 application_name |   state   | sync_state | replay_lag
------------------+-----------+------------+------------
 walreceiver      | streaming | async      |
```

Поле `replay_lag` может быть пустым, если в момент проверки нет новых изменений для применения

Факт задержки задается параметром на реплике:

```bash
docker compose exec -T physical_replica psql -U postgres -d postgres -c "SHOW recovery_min_apply_delay"
```

Ожидаемый результат:

```text
 recovery_min_apply_delay
--------------------------
 5min
```

## Логическая репликация

На primary создается база `replication_demo`, таблица `player_scores`, начальные данные и публикация:

```sql
CREATE PUBLICATION player_scores_publication
FOR TABLE public.player_scores;
```

На логической реплике создается такая же таблица `player_scores`

После запуска стенда нужно создать подписку на `logical_replica`:

```bash
docker compose exec -T logical_replica psql -U postgres -d replication_demo -v ON_ERROR_STOP=1 < 02_create_subscription.sql
```

Подписка:

```sql
CREATE SUBSCRIPTION player_scores_subscription
CONNECTION 'host=primary port=5432 dbname=replication_demo user=replicator password=replicator'
PUBLICATION player_scores_publication
WITH (copy_data = true);
```

Параметр `copy_data = true` копирует уже существующие строки из primary при создании подписки

## Проверка логической репликации

Проверить начальные данные на логической реплике:

```bash
docker compose exec -T logical_replica psql -U postgres -d replication_demo -c "SELECT id, player_name, year_game, points FROM player_scores ORDER BY id"
```

Ожидаемый результат:

```text
 id | player_name | year_game | points
----+-------------+-----------+--------
  1 | Mike        |      2024 |  18.00
  2 | Jack        |      2024 |  14.00
  3 | Jackie      |      2024 |  30.00
  4 | Jet         |      2025 |  30.00
  5 | Luke        |      2025 |  16.00
```

Добавить строки на primary:

```bash
docker compose exec -T primary psql -U postgres -d replication_demo -c "INSERT INTO player_scores (player_name, year_game, points) VALUES ('Anna', 2025, 21), ('Pavel', 2025, 19)"
```

Проверить, что строки появились на логической реплике:

```bash
docker compose exec -T logical_replica psql -U postgres -d replication_demo -c "SELECT id, player_name, year_game, points FROM player_scores ORDER BY id"
```

Ожидаемый результат:

```text
 id | player_name | year_game | points
----+-------------+-----------+--------
  1 | Mike        |      2024 |  18.00
  2 | Jack        |      2024 |  14.00
  3 | Jackie      |      2024 |  30.00
  4 | Jet         |      2025 |  30.00
  5 | Luke        |      2025 |  16.00
  6 | Anna        |      2025 |  21.00
  7 | Pavel       |      2025 |  19.00
```

Проверить физическую реплику сразу после вставки:

```bash
docker compose exec -T physical_replica psql -U postgres -d replication_demo -c "SELECT count(*) AS rows_on_physical_replica FROM player_scores"
```

Ожидаемый результат до истечения 5 минут:

```text
 rows_on_physical_replica
--------------------------
                        5
```

На primary и логической реплике уже 7 строк, а на физической реплике еще 5 строк из-за `recovery_min_apply_delay = '5min'`

## Выполнение готовых скриптов

Создать подписку:

```bash
docker compose exec -T logical_replica psql -U postgres -d replication_demo -v ON_ERROR_STOP=1 < 02_create_subscription.sql
```

Добавить строки на primary и проверить состояние репликации:

```bash
docker compose exec -T primary psql -U postgres -d postgres -v ON_ERROR_STOP=1 < 03_check_replication.sql
```

Проверить данные на логической реплике:

```bash
docker compose exec -T logical_replica psql -U postgres -d replication_demo -v ON_ERROR_STOP=1 < 04_check_logical_replica.sql
```

## Проблемы

Физическую реплику нельзя просто запустить как обычный пустой PostgreSQL-контейнер

Сначала нужно получить копию данных primary через `pg_basebackup`, поэтому для `physical_replica` используется отдельный entrypoint

Логическая подписка создается отдельным шагом после запуска стенда, потому что для нее должны быть доступны оба сервера: primary с публикацией и logical replica с целевой таблицей

Для логической репликации таблица на подписчике должна существовать заранее и иметь совместимую структуру

## Остановка

```bash
docker compose down
```

Удалить данные:

```bash
docker compose down -v
```
