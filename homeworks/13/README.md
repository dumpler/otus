# Домашнее задание 13

## Цель

Создать отчетные выборки для MySQL с использованием `CASE`, `HAVING`, `ROLLUP` и `GROUPING()`

Вместо продуктов, товаров и категорий используются сущности для выпускного проекта:

- офисы
- зоны
- рабочие места
- типы рабочих мест
- бронирования
- статусы бронирований

## Файлы

- `docker-compose.yml` - MySQL-контейнер
- `initdb/01_office_booking_reports.sql` - схема и тестовые данные
- `01_reports.sql` - отчетные выборки

## Запуск MySQL

```bash
docker compose up -d
```

## Выполнение отчетов

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 01_reports.sql
```

## Группировка с CASE и HAVING

Смысл задания про продукты перенес на рабочие места

Для рабочих мест считаются:

- минимальная вместимость
- максимальная вместимость
- количество рабочих мест
- количество активных рабочих мест

Группировка строится не только по типу из таблицы, но и по бизнес-группе через `CASE`

```sql
SELECT
    o.name AS office_name,
    CASE
        WHEN wt.code = 'meeting_room' THEN 'meeting'
        WHEN z.is_quiet_zone = 1 THEN 'quiet'
        ELSE 'open_space'
    END AS workplace_group,
    min(w.seats_count) AS min_seats,
    max(w.seats_count) AS max_seats,
    count(*) AS workplaces_count,
    sum(w.is_active = 1) AS active_workplaces_count
FROM workplaces w
JOIN zones z ON z.id = w.zone_id
JOIN offices o ON o.id = z.office_id
JOIN workplace_types wt ON wt.id = w.type_id
GROUP BY
    o.name,
    CASE
        WHEN wt.code = 'meeting_room' THEN 'meeting'
        WHEN z.is_quiet_zone = 1 THEN 'quiet'
        ELSE 'open_space'
    END
HAVING count(*) >= 2
ORDER BY office_name, workplace_group;
```

`HAVING count(*) >= 2` оставляет только группы, где есть минимум два рабочих места

## Самое большое и самое маленькое рабочее место в каждой зоне

Вместо самого дорогого и самого дешевого товара выбирается самое большое и самое маленькое рабочее место по `seats_count`

```sql
WITH ranked_workplaces AS (
    SELECT
        z.id AS zone_id,
        z.name AS zone_name,
        w.code AS workplace_code,
        w.name AS workplace_name,
        w.seats_count,
        row_number() OVER (
            PARTITION BY z.id
            ORDER BY w.seats_count DESC, w.code
        ) AS max_rank,
        row_number() OVER (
            PARTITION BY z.id
            ORDER BY w.seats_count ASC, w.code
        ) AS min_rank
    FROM workplaces w
    JOIN zones z ON z.id = w.zone_id
    WHERE w.is_active = 1
)
SELECT
    zone_name,
    max(CASE WHEN max_rank = 1 THEN workplace_code END) AS largest_workplace_code,
    max(CASE WHEN max_rank = 1 THEN workplace_name END) AS largest_workplace_name,
    max(CASE WHEN max_rank = 1 THEN seats_count END) AS max_seats,
    max(CASE WHEN min_rank = 1 THEN workplace_code END) AS smallest_workplace_code,
    max(CASE WHEN min_rank = 1 THEN workplace_name END) AS smallest_workplace_name,
    max(CASE WHEN min_rank = 1 THEN seats_count END) AS min_seats
FROM ranked_workplaces
GROUP BY zone_id, zone_name
ORDER BY zone_name;
```

Такой отчет нужен, чтобы видеть крайние варианты вместимости в каждой зоне

Например для meeting-зоны это показывает самую маленькую и самую большую переговорную

## ROLLUP по рабочим местам

`ROLLUP` используется для подсчета рабочих мест по зонам, офисам и всему проекту

`GROUPING()` помогает заменить итоговые `NULL` на понятные подписи

```sql
SELECT
    IF(GROUPING(o.name), 'All offices', o.name) AS office_name,
    IF(GROUPING(z.name), 'All zones', z.name) AS zone_name,
    count(w.id) AS workplaces_count,
    sum(w.is_active = 1) AS active_workplaces_count
FROM offices o
JOIN zones z ON z.office_id = o.id
JOIN workplaces w ON w.zone_id = z.id
GROUP BY o.name, z.name WITH ROLLUP;
```

Этот отчет показывает:

- количество рабочих мест в каждой зоне
- итог по каждому офису
- общий итог по всем офисам

Пример результата:

```text
office_name                zone_name       workplaces_count  active_workplaces_count
Moscow Main Office         Meeting Zone A  2                 2
Moscow Main Office         Open Space A    3                 2
Moscow Main Office         Quiet Zone A    2                 2
Moscow Main Office         All zones       7                 6
Saint Petersburg Center    Open Space B    2                 2
Saint Petersburg Center    Quiet Zone B    1                 1
Saint Petersburg Center    All zones       3                 3
All offices                All zones       10                9
```

## ROLLUP по бронированиям

Дополнительно сделан отчет по бронированиям в разрезе офисов и статусов

```sql
SELECT
    IF(GROUPING(o.name), 'All offices', o.name) AS office_name,
    IF(GROUPING(bs.code), 'All statuses', bs.code) AS booking_status,
    count(b.id) AS bookings_count
FROM bookings b
JOIN workplaces w ON w.id = b.workplace_id
JOIN zones z ON z.id = w.zone_id
JOIN offices o ON o.id = z.office_id
JOIN booking_statuses bs ON bs.id = b.status_id
GROUP BY o.name, bs.code WITH ROLLUP;
```

Такой отчет нужен, чтобы быстро увидеть распределение бронирований по статусам внутри офисов и общий итог

Пример результата:

```text
office_name                booking_status  bookings_count
Moscow Main Office         cancelled       2
Moscow Main Office         completed       1
Moscow Main Office         confirmed       4
Moscow Main Office         All statuses    7
Saint Petersburg Center    completed       1
Saint Petersburg Center    confirmed       2
Saint Petersburg Center    All statuses    3
All offices                All statuses    10
```

## Остановка

```bash
docker compose down
```

Удалить данные:

```bash
docker compose down -v
```
