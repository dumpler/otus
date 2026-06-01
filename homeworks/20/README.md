# Домашнее задание 20

## Цель

Развернуть кластер MySQL из трех узлов и проверить его состояние

Для задания используется Percona XtraDB Cluster

## Файлы

- `docker-compose.yml` - три узла PXC
- `ssl/` - общий CA и сертификат для межнодового TLS
- `config/ssl.cnf` - подключение общего сертификата в конфиг MySQL
- `01_seed.sql` - тестовая база `office_booking_cluster`
- `02_status.sql` - статус кластера и проверка таблиц
- `03_after_failure_insert.sql` - вставка данных при остановленной одной ноде

## Запуск кластера

Сначала запускается первая нода:

```bash
docker compose up -d pxc1
```

Нужно дождаться завершения bootstrap первой ноды:

```bash
docker compose logs pxc1 | grep "MySQL init process done"
```

После этого ноды запускаются по одной:

```bash
docker compose up -d pxc2
```

Дождаться синхронизации:

```bash
docker compose logs pxc2 | grep "Synchronized with group, ready for connections"
```

Запустить третью ноду:

```bash
docker compose up -d pxc3
```

Дождаться синхронизации:

```bash
docker compose logs pxc3 | grep "Synchronized with group, ready for connections"
```

## Проверка статуса кластера

Проверить каждую ноду:

```bash
docker compose exec -T pxc1 mysql -u root -p12345 < 02_status.sql
docker compose exec -T pxc2 mysql -u root -p12345 < 02_status.sql
docker compose exec -T pxc3 mysql -u root -p12345 < 02_status.sql
```

Ожидаемые признаки исправного кластера:

```text
wsrep_cluster_size          3
wsrep_cluster_status        Primary
wsrep_local_state_comment   Synced
wsrep_ready                 ON
```

## Загрузка данных

Данные загружаются на первую ноду:

```bash
docker compose exec -T pxc1 mysql -u root -p12345 < 01_seed.sql
```

После этого на каждой ноде должны быть таблицы:

```text
offices
workplaces
```

И одинаковое количество рабочих мест:

```text
workplaces_count
4
```

## Проверка отказа одной ноды

Остановить вторую ноду:

```bash
docker compose stop pxc2
```

Проверить, что кластер продолжает работать на `pxc1` и `pxc3`:

```bash
docker compose exec -T pxc1 mysql -u root -p12345 < 02_status.sql
docker compose exec -T pxc3 mysql -u root -p12345 < 02_status.sql
```

Ожидаемый размер кластера:

```text
wsrep_cluster_size  2
```

Вставить данные при остановленной ноде:

```bash
docker compose exec -T pxc1 mysql -u root -p12345 < 03_after_failure_insert.sql
```

Кластер должен принять запись, потому что две ноды из трех сохраняют кворум

Вернуть ноду:

```bash
docker compose up -d pxc2
```

После синхронизации на всех трех нодах ожидается:

```text
workplaces_count
5
```

## Остановка

```bash
docker compose down -v
```
