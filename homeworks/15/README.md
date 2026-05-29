# Домашнее задание 14

## Цель

Научиться проектировать, использовать и анализировать оконные функции с учётом граничных случаев

## Файлы

- `docker-compose.yml` - MySQL-контейнер
- `initdb/01_stores_init.sql` - создание базы `stores_data`, таблиц `stores` и `sales`
- `01_stores_seed.sql` - хранимая процедура для начальных данных и ее вызов
- `02_cumulative_sales.sql` - запрос для получения нарастающего итога продаж по каждому магазину с группировкой по месяцам
- `03_moving_average.sql` - запрос для 7-дневного скользящего среднего за последний месяц по самому плодовитому магазину

Тестовые строки в `01_stores_seed.sql` создаются через рекурсивный CTE

## Запуск MySQL

```bash
docker compose up -d
```

## Тестовые данные

Добавить начальные данные:

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 01_stores_seed.sql
```

## Итог продаж по каждому магазину с группировкой по месяцам:

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 02_cumulative_sales.sql
```

## 7-дневное скользящее среднее за последний месяц по самому плодовитому магазину:

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 03_moving_average.sql
```

## Граничные случаи:

- В нарастающем итоге сначала агрегируем продажи по месяцам, а уже потом считаем оконную сумму, иначе итог был бы по отдельным продажам

- В скользящем среднем первые 6 дней считаются по доступному количеству дней, а не по полным 7 дням

- Самый плодовитый магазин определяется по количеству продаж, а не по сумме выручки

- Продажи с одинаковыми датами сначала агрегируются по дням, чтобы один день не учитывался несколько раз

## Проблемы

Необходимость изменять `cte_max_recursion_depth`, чтобы сгенерировать достаточный объем данных

Если использовать `WHILE` то это 100000 `INSERT` в отличие от `WITH RECURSIVE`, который выполняется за один `INSERT`

Еще быстрее через `CROSS JOIN`, но он страшный

```sql
INSERT INTO sales(store_id, date, sale_amount)
SELECT
    CASE
        WHEN RAND() < 0.73 THEN 1
        ELSE FLOOR(2 + RAND() * 9)
    END,
    NOW()
        - INTERVAL FLOOR(RAND() * 730) DAY
        - INTERVAL FLOOR(RAND() * 86400) SECOND,
    ROUND(10 + RAND() * 990, 2)
FROM
    (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
CROSS JOIN
    (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
CROSS JOIN
    (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
CROSS JOIN
    (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d
CROSS JOIN
    (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) e
LIMIT 100000;
```

## Остановка

```bash
docker compose down
```

Удалить данные:

```bash
docker compose down -v
```
