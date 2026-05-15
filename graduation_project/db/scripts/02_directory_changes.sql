-- Выполнять во внешней базе данных directory_db
-- docker compose exec -T directory_db psql -U directory_user -d directory_service -f /scripts/02_directory_changes.sql

-- Добавляем новый отдел во внешнем каталоге
-- Он должен попасть в основную БД через логическую репликацию
INSERT INTO office.departments (
    code,
    name
)
VALUES (
    'product',
    'Product'
)
ON CONFLICT (code) DO UPDATE
SET
    name = EXCLUDED.name,
    is_active = TRUE,
    updated_at = now();

-- Переименовываем существующий отдел
-- Это демонстрирует репликацию UPDATE для справочника
UPDATE office.departments
SET
    name = 'People Operations',
    updated_at = now()
WHERE code = 'hr';

-- Добавляем новую роль во внешнем каталоге
-- Она понадобится для сотрудника, который управляет точками рабочих мест на плане этажа
INSERT INTO office.roles (
    code,
    name,
    description
)
VALUES (
    'floor_manager',
    'Floor manager',
    'Can manage workplace map points on assigned floors'
)
ON CONFLICT (code) DO UPDATE
SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    is_active = TRUE,
    updated_at = now();

-- Добавляем нового сотрудника
-- Сотрудник ссылается на новый отдел product
INSERT INTO office.employees (
    id,
    external_id,
    email,
    full_name,
    department_code,
    position_name
)
VALUES (
    5,
    'ad-1005',
    'maria.kuznetsova@example.com',
    'Maria Kuznetsova',
    'product',
    'QA Engineer'
)
ON CONFLICT (id) DO UPDATE
SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    department_code = EXCLUDED.department_code,
    position_name = EXCLUDED.position_name,
    is_active = TRUE,
    source_updated_at = now();

-- Меняем должность существующего сотрудника
-- Это демонстрирует репликацию UPDATE для employees
UPDATE office.employees
SET
    position_name = 'Senior Backend Developer',
    source_updated_at = now()
WHERE external_id = 'ad-1001';

-- Деактивируем сотрудника вместо физического удаления
-- Такой подход типичен для справочников пользователей из AD/LDAP
UPDATE office.employees
SET
    is_active = FALSE,
    source_updated_at = now()
WHERE external_id = 'ad-1003';

-- Удаляем назначение роли у сотрудника
-- Так показываем репликацию DELETE на связующей таблице employee_roles
DELETE FROM office.employee_roles
WHERE employee_id = 4
  AND role_code = 'employee';

-- Назначаем роли новому сотруднику
-- Одна роль обычная, вторая дает права управления планом этажа
INSERT INTO office.employee_roles (employee_id, role_code)
VALUES
    (5, 'employee'),
    (5, 'floor_manager')
ON CONFLICT (employee_id, role_code) DO NOTHING;

-- Выводим итоговый справочник отделов во внешнем каталоге
SELECT
    id,
    code,
    name,
    is_active
FROM office.departments
ORDER BY id;

-- Выводим итоговый справочник ролей во внешнем каталоге
SELECT
    id,
    code,
    name,
    is_active
FROM office.roles
ORDER BY id;

-- Выводим сотрудников вместе с отделами и ролями
-- По этому результату удобно сравнивать данные с основной БД после репликации
SELECT
    e.id,
    e.external_id,
    e.email,
    e.full_name,
    e.department_code,
    d.name AS department_name,
    e.position_name,
    e.is_active,
    string_agg(er.role_code, ', ' ORDER BY er.role_code) AS roles
FROM office.employees e
LEFT JOIN office.departments d ON d.code = e.department_code
LEFT JOIN office.employee_roles er ON er.employee_id = e.id
GROUP BY
    e.id,
    e.external_id,
    e.email,
    e.full_name,
    e.department_code,
    d.name,
    e.position_name,
    e.is_active
ORDER BY e.id;

