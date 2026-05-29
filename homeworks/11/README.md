# Домашнее задание 11

## Цель

Научиться соединять таблицы и использовать условия в SQL-выборке на MySQL

Выполнены оба блока задания:

- запросы по своей базе
- тестовое задание с категориями, товарами, генерацией 200000 строк и постраничной выдачей

Задания разделены на две базы данных:

- `office_booking_selects` - выборки по своей базе
- `product_testing` - тестовое задание с категориями и товарами

## Файлы

- `docker-compose.yml` - MySQL-контейнер
- `initdb/01_office_booking_selects.sql` - база для выборок по своей модели
- `initdb/02_product_testing.sql` - база для тестового задания с товарами
- `01_project_selects.sql` - `INNER JOIN`, `LEFT JOIN` и 5 запросов с `WHERE`
- `02_generate_products.sql` - запуск процедуры генерации 20 категорий и 200000 товаров
- `03_pagination.sql` - запрос постраничной выдачи товаров и `EXPLAIN`

## Запуск MySQL

```bash
docker compose up -d
```

## Задание по своей базе

Запустить запросы:

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 01_project_selects.sql
```

### INNER JOIN

Запрос показывает бронирования вместе с сотрудником, рабочим местом и статусом

```sql
SELECT
    b.id,
    e.email,
    w.code AS workplace_code,
    bs.code AS status_code,
    b.starts_at,
    b.ends_at
FROM bookings b
INNER JOIN employees e ON e.id = b.employee_id
INNER JOIN workplaces w ON w.id = b.workplace_id
INNER JOIN booking_statuses bs ON bs.id = b.status_id
ORDER BY b.starts_at;
```

Такой запрос нужен для экрана списка бронирований

### LEFT JOIN

Запрос показывает всех сотрудников и отдел, если он назначен

```sql
SELECT
    e.id,
    e.email,
    e.position_name,
    d.name AS department_name
FROM employees e
LEFT JOIN departments d ON d.id = e.department_id
ORDER BY e.id;
```

Такой запрос нужен для контроля сотрудников без отдела

Например сотрудник с должностью `Contractor` и email `sergey.orlov@example.com` попадет в результат с `NULL` в `department_name`

## WHERE-запросы

### Равенство

```sql
SELECT
    id,
    email,
    position_name
FROM employees
WHERE is_active = 1
ORDER BY id;
```

Нужно для выборки только активных сотрудников

### BETWEEN

```sql
SELECT
    id,
    workplace_id,
    starts_at,
    ends_at
FROM bookings
WHERE starts_at BETWEEN '2026-06-01 00:00:00' AND '2026-06-07 23:59:59'
ORDER BY starts_at;
```

Нужно для календаря бронирований на неделю

### IN

```sql
SELECT
    id,
    email,
    department_id
FROM employees
WHERE department_id IN (1, 4)
ORDER BY id;
```

Нужно для отчета по выбранным отделам

### LIKE

```sql
SELECT
    id,
    email,
    last_name
FROM employees
WHERE email LIKE '%@example.com'
ORDER BY email;
```

Нужно для поиска сотрудников по корпоративному домену

### AND

```sql
SELECT
    id,
    code,
    name
FROM workplaces
WHERE has_monitor = 1
  AND is_active = 1
ORDER BY code;
```

Нужно для подбора активных рабочих мест с монитором

## Тестовое задание

В задании были предложены таблицы `categories` и `products`

Типы скорректированы:

- `category_id` в `products` изменен с `VARCHAR(32)` на `BIGINT UNSIGNED`, чтобы тип совпадал с `categories.category_id`
- `price` сделан `INT UNSIGNED NOT NULL UNIQUE`, потому что цены должны быть положительными и уникальными
- `rating` сделан `TINYINT UNSIGNED NOT NULL` с `CHECK (rating BETWEEN 1 AND 5)`
- `status` сделан `ENUM('В наличии', 'Распродан')`, чтобы нельзя было записать произвольный статус
- добавлена generated column `status_sort`, чтобы эффективно сортировать сначала товары в наличии
- добавлен индекс `idx_products_page (status_sort, price)` для постраничной выдачи
- добавлены триггеры валидации `price` и `rating`, потому что в `mysql:8.0.15` `CHECK` не стоит использовать как единственный механизм защиты

DDL:

```sql
CREATE TABLE IF NOT EXISTS categories (
    category_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(32) NOT NULL,
    PRIMARY KEY (category_id),
    UNIQUE KEY uq_categories_title (title)
) ENGINE=InnoDB;
```

Дополнительная защита бизнес-логики:

```sql
CREATE TRIGGER trg_products_validate_insert
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
    IF NEW.price = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Product price must be greater than zero';
    END IF;

    IF NEW.rating < 1 OR NEW.rating > 5 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Product rating must be between 1 and 5';
    END IF;
END;
```

```sql
CREATE TABLE IF NOT EXISTS products (
    product_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(64) NOT NULL,
    category_id BIGINT UNSIGNED NOT NULL,
    price INT UNSIGNED NOT NULL,
    rating TINYINT UNSIGNED NOT NULL,
    status ENUM('В наличии', 'Распродан') NOT NULL,
    status_sort TINYINT UNSIGNED
        GENERATED ALWAYS AS (
            CASE status
                WHEN 'В наличии' THEN 0
                ELSE 1
            END
        ) STORED,
    PRIMARY KEY (product_id),
    UNIQUE KEY uq_products_price (price),
    KEY idx_products_category (category_id),
    KEY idx_products_page (status_sort, price),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES categories (category_id),
    CONSTRAINT chk_products_price_positive
        CHECK (price > 0),
    CONSTRAINT chk_products_rating_range
        CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;
```

## Генерация данных

Запустить генерацию:

```bash
docker compose exec -T otusdb mysql -u root -p12345 < 02_generate_products.sql
```

Процедура `generate_test_products` создает:

- 20 категорий
- 10000 товаров в каждой категории
- 200000 товаров суммарно

После каждой вставки категории используется:

```sql
SET current_category_id = LAST_INSERT_ID();
```

Цены рассчитываются так:

```sql
(category_number - 1) * 10000 + n
```

Поэтому цены уникальны во всей таблице от `1` до `200000`

Ожидаемая проверка:

```text
categories_count
20

products_count  unique_prices_count  min_price  max_price
200000          200000               1          200000
```

## Постраничная выдача

Товары должны выводиться так:

- сначала все товары в наличии по возрастанию цены
- затем все распроданные товары по возрастанию цены
- по 50 товаров на страницу

Для первой страницы:

```sql
SELECT
    product_id,
    title,
    category_id,
    price,
    rating,
    status
FROM products
ORDER BY status_sort, price
LIMIT 50;
```

Для следующей страницы используется keyset пагинация

Например если последняя строка предыдущей страницы имела `status_sort = 0` и `price = 62`:

```sql
SET @last_status_sort = 0;
SET @last_price = 62;

SELECT
    product_id,
    title,
    category_id,
    price,
    rating,
    status
FROM products
WHERE (status_sort, price) > (@last_status_sort, @last_price)
ORDER BY status_sort, price
LIMIT 50;
```

Такой способ лучше, чем `LIMIT 50 OFFSET N`, потому что MySQL не нужно пропускать все предыдущие строки

Индекс:

```sql
KEY idx_products_page (status_sort, price)
```

позволяет идти по данным в нужном порядке

Проверка `EXPLAIN` для keyset-запроса показывает использование индекса:

```text
type  key                rows  Extra
index idx_products_page  50    Using where
```

## Остановка

```bash
docker compose down
```

Удалить данные:

```bash
docker compose down -v
```
