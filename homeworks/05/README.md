# Домашнее задание 05

## Цель

Написать DML-запросы для PostgreSQL на базе проекта `office_booking`

В задании используются:

- `SELECT` с регулярным выражением
- `INNER JOIN`
- `LEFT JOIN`
- `INSERT INTO` с выводом добавленных строк
- `UPDATE FROM`
- `DELETE USING`
- пример утилиты `COPY`

## Файлы

- `docker-compose.yml` - PostgreSQL и pgAdmin
- `01_schema.sql` - схема базы для выполнения DML-запросов
- `02_seed.sql` - начальные данные
- `03_dml.sql` - запросы по заданию

## Запуск PostgreSQL

```bash
docker compose up -d
```

## Подготовка базы

Создать схемы и таблицы:

```bash
docker compose exec -T postgres psql -U postgres -d office_booking -v ON_ERROR_STOP=1 < 01_schema.sql
```

Добавить начальные данные:

```bash
docker compose exec -T postgres psql -U postgres -d office_booking -v ON_ERROR_STOP=1 < 02_seed.sql
```

Запустить DML-запросы:

```bash
docker compose exec -T postgres psql -U postgres -d office_booking -v ON_ERROR_STOP=1 < 03_dml.sql
```

## SELECT с регулярным выражением

Запрос ищет сотрудников, у которых email соответствует шаблону `name.surname@example.com`

Используется оператор `~`

```sql
SELECT
    id,
    email,
    last_name,
    first_name
FROM office.employees
WHERE email ~ '^[a-z]+\.[a-z]+@example\.com$'
ORDER BY id;
```

## INNER JOIN и LEFT JOIN

`INNER JOIN` возвращает только строки, для которых есть совпадения во всех соединяемых таблицах

В примере сотрудник попадет в результат только если у него есть отдел и назначенная роль

```sql
SELECT
    e.id,
    e.email,
    d.name AS department_name,
    er.role_code
FROM office.employees e
INNER JOIN office.departments d ON d.code = e.department_code
INNER JOIN office.employee_roles er ON er.employee_id = e.id
ORDER BY e.id, er.role_code;
```

`LEFT JOIN` сохраняет все строки из левой таблицы `office.employees`

Если у сотрудника нет роли, сотрудник все равно попадет в результат, но поле `role_code` будет `NULL`

```sql
SELECT
    e.id,
    e.email,
    d.name AS department_name,
    er.role_code
FROM office.employees e
LEFT JOIN office.departments d ON d.code = e.department_code
LEFT JOIN office.employee_roles er ON er.employee_id = e.id
ORDER BY e.id, er.role_code;
```

Порядок соединений в `FROM` влияет на результат для `LEFT JOIN`, потому что левая таблица задает набор строк, который нужно сохранить

Для `INNER JOIN` порядок обычно не меняет итоговый набор строк, потому что остаются только совпавшие записи, но оптимизатор может выбрать другой план выполнения

## INSERT INTO с выводом добавленных строк

Запрос добавляет нового сотрудника и сразу выводит добавленную строку через `RETURNING`

```sql
INSERT INTO office.employees (
    id,
    email,
    last_name,
    first_name,
    middle_name,
    department_code,
    position_name
)
VALUES (
    6,
    'sergey.orlov@example.com',
    'Orlov',
    'Sergey',
    'Petrovich',
    'it',
    'DevOps Engineer'
)
RETURNING
    id,
    email,
    last_name,
    first_name,
    department_code,
    position_name;
```

После добавления сотрудника ему назначается роль `employee`, чтобы в примере `DELETE USING` была строка для удаления

## UPDATE FROM

Запрос обновляет должности сотрудников IT-отдела через соединение с `office.departments`

```sql
UPDATE office.employees e
SET
    position_name = 'Senior ' || e.position_name,
    source_updated_at = now()
FROM office.departments d
WHERE d.code = e.department_code
  AND d.code = 'it'
  AND e.position_name NOT LIKE 'Senior %'
RETURNING
    e.id,
    e.email,
    d.name AS department_name,
    e.position_name;
```

## DELETE USING

Запрос удаляет роли сотрудника через соединение с таблицей сотрудников

Для этого используется форма `DELETE ... USING`

```sql
DELETE FROM office.employee_roles er
USING office.employees e
WHERE e.id = er.employee_id
  AND e.email = 'sergey.orlov@example.com'
RETURNING
    er.employee_id,
    er.role_code;
```

## COPY

Пример показывает загрузку CSV-данных во временную таблицу через `COPY`

```sql
CREATE TEMP TABLE imported_departments (
    code TEXT,
    name TEXT
);

COPY imported_departments (code, name)
FROM STDIN
WITH (FORMAT csv, HEADER true);
code,name
legal,Legal
support,Customer Support
\.
```

## Остановка

```bash
docker compose down
```

Удалить данные:

```bash
docker compose down -v
```
