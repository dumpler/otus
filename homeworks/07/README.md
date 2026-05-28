# Домашнее задание 07

## Цель

Использовать CTE и оконную функцию `LAG` для подсчета очков игроков за текущий и предыдущий год

В задании используются:

- создание таблицы
- вставка данных
- группировка по году
- CTE
- оконная функция `LAG`

## Файлы

- `docker-compose.yml` - PostgreSQL и pgAdmin для выполнения задания
- `01_statistic.sql` - таблица, данные и запросы

## Запуск PostgreSQL

```bash
docker compose up -d
```

## Выполнение задания

```bash
docker compose exec -T postgres psql -U postgres -d statistics -v ON_ERROR_STOP=1 < 01_statistic.sql
```

## Создание таблицы

```sql
CREATE TABLE statistic (
    player_name VARCHAR(100) NOT NULL,
    player_id INT NOT NULL,
    year_game SMALLINT NOT NULL CHECK (year_game > 0),
    points DECIMAL(12,2) CHECK (points >= 0),
    PRIMARY KEY (player_name, year_game)
);
```

Таблица хранит очки игроков по годам

Первичный ключ задан по `player_name` и `year_game`, поэтому у одного игрока может быть только одна строка за конкретный год

## Заполнение данными

```sql
INSERT INTO statistic(player_name, player_id, year_game, points)
VALUES
    ('Mike', 1, 2018, 18),
    ('Jack', 2, 2018, 14),
    ('Jackie', 3, 2018, 30),
    ('Jet', 4, 2018, 30),
    ('Luke', 1, 2019, 16),
    ('Mike', 2, 2019, 14),
    ('Jack', 3, 2019, 15),
    ('Jackie', 4, 2019, 28),
    ('Jet', 5, 2019, 25),
    ('Luke', 1, 2020, 19),
    ('Mike', 2, 2020, 17),
    ('Jack', 3, 2020, 18),
    ('Jackie', 4, 2020, 29),
    ('Jet', 5, 2020, 27);
```

## Сумма очков по годам

Запрос считает сумму очков всех игроков за каждый год

```sql
SELECT
    year_game,
    sum(points) AS total_points
FROM statistic
GROUP BY year_game
ORDER BY year_game;
```

Результат:

```text
 year_game | total_points
-----------+--------------
      2018 |        92.00
      2019 |        98.00
      2020 |       110.00
```

## Сумма очков через CTE

CTE `points_by_year` сначала собирает сумму очков по годам, а внешний запрос выводит результат с сортировкой

```sql
WITH points_by_year AS (
    SELECT
        year_game,
        sum(points) AS total_points
    FROM statistic
    GROUP BY year_game
)
SELECT
    year_game,
    total_points
FROM points_by_year
ORDER BY year_game;
```

Результат:

```text
 year_game | total_points
-----------+--------------
      2018 |        92.00
      2019 |        98.00
      2020 |       110.00
```

## Очки за текущий и предыдущий год

Функция `LAG` берет значение суммы очков из предыдущей строки в порядке годов

Так можно вывести сумму очков за текущий год и сумму очков за предыдущий год в одной строке

```sql
WITH points_by_year AS (
    SELECT
        year_game,
        sum(points) AS total_points
    FROM statistic
    GROUP BY year_game
),
points_with_previous_year AS (
    SELECT
        year_game,
        total_points AS current_year_points,
        lag(total_points) OVER (ORDER BY year_game) AS previous_year_points
    FROM points_by_year
)
SELECT
    year_game,
    current_year_points,
    previous_year_points,
    current_year_points - previous_year_points AS points_difference
FROM points_with_previous_year
ORDER BY year_game;
```

Результат:

```text
 year_game | current_year_points | previous_year_points | points_difference
-----------+---------------------+----------------------+-------------------
      2018 |               92.00 |                      |
      2019 |               98.00 |                92.00 |              6.00
      2020 |              110.00 |                98.00 |             12.00
```

Для 2018 года значение предыдущего года равно `NULL`, потому что в выборке нет строки до 2018 года

## Остановка

```bash
docker compose down
```

Удалить данные:

```bash
docker compose down -v
```
