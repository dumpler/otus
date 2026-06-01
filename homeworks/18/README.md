# Домашнее задание 18

## Цель

Восстановить конкретную таблицу из сжатого и зашифрованного XtraBackup

В задании требуется восстановить таблицу `world.city`

## Файлы

- `backup.xbs.gz.aes` - зашифрованный backup из материалов
- `world.dump.sql` - структура базы `world`
- `01_discard_city_tablespace.sql` - удаление tablespace для `city`
- `02_import_city_tablespace.sql` - импорт tablespace для `city`
- `03_check_counts.sql` - контрольный запрос

## Проверка структуры

Отдельного файла `world.dump.sql` из материалов в проекте не было

Внутри `backup.xbs.gz.aes` SQL-дампа структуры тоже нет

После расшифровки и распаковки backup содержит физические файлы:

```text
world/city.ibd
world/country.ibd
world/countrylanguage.ibd
```

То есть структура не лежит отдельным SQL-файлом внутри архива

Поэтому `world.dump.sql` был получен из подготовленного полного backup через `mysqldump --no-data`

## Расшифровка и распаковка backup

```bash
mkdir -p /tmp/otus_hw18_export
chmod 777 /tmp/otus_hw18_export
```

```bash
openssl aes-256-cbc -d -salt -pbkdf2 -k "password" \
  -in backup.xbs.gz.aes \
| gzip -dc \
| docker run --rm -i \
    -v /tmp/otus_hw18_export:/restore \
    percona/percona-xtrabackup:8.0 \
    xbstream -x -C /restore
```

## Подготовка backup для импорта таблицы

```bash
docker run --rm \
  -v /tmp/otus_hw18_export:/restore \
  percona/percona-xtrabackup:8.0 \
  xtrabackup --prepare --export --target-dir=/restore
```

После этого появились файлы:

```text
/tmp/otus_hw18_export/world/city.ibd
/tmp/otus_hw18_export/world/city.cfg
```

## Создание чистой базы

```bash
docker run -d \
  --name homework_18_target \
  -e MYSQL_ROOT_PASSWORD=12345 \
  mysql:8.0
```

Применить структуру:

```bash
docker exec -i homework_18_target mysql -u root -p12345 < world.dump.sql
```

## Восстановление только таблицы city

Удалить tablespace пустой таблицы `city`:

```bash
docker exec -i homework_18_target mysql -u root -p12345 < 01_discard_city_tablespace.sql
```

Скопировать файлы из подготовленного backup:

```bash
docker cp /tmp/otus_hw18_export/world/city.ibd homework_18_target:/var/lib/mysql/world/city.ibd
docker cp /tmp/otus_hw18_export/world/city.cfg homework_18_target:/var/lib/mysql/world/city.cfg
docker exec homework_18_target chown mysql:mysql /var/lib/mysql/world/city.ibd /var/lib/mysql/world/city.cfg
```

Импортировать tablespace:

```bash
docker exec -i homework_18_target mysql -u root -p12345 < 02_import_city_tablespace.sql
```

## Контрольный запрос

В задании указан `count()`, но в MySQL нужно использовать `COUNT(*)`

```bash
docker exec -i homework_18_target mysql -u root -p12345 < 03_check_counts.sql
```

Результат:

```text
t_name           cnt
city             4080
city (RUS)       190
country          0
countrylanguage  0
```

`country` и `countrylanguage` равны `0`, потому что из backup восстанавливалась только таблица `city`

## Очистка

```bash
docker stop homework_18_target
docker rm homework_18_target
```
