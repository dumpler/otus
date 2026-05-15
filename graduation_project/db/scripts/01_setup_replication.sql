-- Выполнять в основной базе данных
-- docker compose exec -T office_booking_db psql -U office_booking_user -d office_booking -f /scripts/01_setup_replication.sql

-- Удаляем старые подписки, чтобы сценарий можно было запускать повторно
DROP SUBSCRIPTION IF EXISTS directory_employees_subscription;
DROP SUBSCRIPTION IF EXISTS directory_employee_roles_subscription;
DROP SUBSCRIPTION IF EXISTS directory_departments_subscription;
DROP SUBSCRIPTION IF EXISTS directory_roles_subscription;

-- Очищаем реплицируемые таблицы в основной БД
-- CASCADE также очищает зависимые таблицы сотрудников, ролей сотрудников и бронирований
TRUNCATE TABLE office.roles, office.departments CASCADE;

-- Создаем подписку на роли пользователей
-- Эти данные нужны до назначения ролей сотрудникам
CREATE SUBSCRIPTION directory_roles_subscription
CONNECTION 'host=directory_db port=5432 dbname=directory_service user=directory_user password=directory_password'
PUBLICATION directory_roles_publication
WITH (
    copy_data = true,
    create_slot = true,
    enabled = true
);

-- Создаем подписку на отделы
-- Отделы нужны до загрузки сотрудников, потому что employees.department_code ссылается на departments.code
CREATE SUBSCRIPTION directory_departments_subscription
CONNECTION 'host=directory_db port=5432 dbname=directory_service user=directory_user password=directory_password'
PUBLICATION directory_departments_publication
WITH (
    copy_data = true,
    create_slot = true,
    enabled = true
);

-- Даем PostgreSQL время завершить первичное копирование ролей и отделов
SELECT pg_sleep(2);

-- Создаем подписку на сотрудников
-- На этом шаге проверяется репликация таблицы, зависящей от справочника отделов
CREATE SUBSCRIPTION directory_employees_subscription
CONNECTION 'host=directory_db port=5432 dbname=directory_service user=directory_user password=directory_password'
PUBLICATION directory_employees_publication
WITH (
    copy_data = true,
    create_slot = true,
    enabled = true
);

-- Даем PostgreSQL время завершить первичное копирование сотрудников
SELECT pg_sleep(2);

-- Создаем подписку на назначения ролей сотрудникам
-- Это связующая таблица многие-ко-многим между employees и roles
CREATE SUBSCRIPTION directory_employee_roles_subscription
CONNECTION 'host=directory_db port=5432 dbname=directory_service user=directory_user password=directory_password'
PUBLICATION directory_employee_roles_publication
WITH (
    copy_data = true,
    create_slot = true,
    enabled = true
);

-- Показываем созданные подписки и их состояние
SELECT
    subname,
    subenabled
FROM pg_subscription
WHERE subname IN (
    'directory_departments_subscription',
    'directory_employees_subscription',
    'directory_employee_roles_subscription',
    'directory_roles_subscription'
)
ORDER BY subname;

