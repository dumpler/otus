INSERT INTO office.departments (id, code, name)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'it', 'IT'),
    (2, 'hr', 'HR'),
    (3, 'finance', 'Finance'),
    (4, 'sales', 'Sales'),
    (5, 'product', 'Product'),
    (6, 'legal', 'Legal'),
    (7, 'marketing', 'Marketing'),
    (8, 'support', 'Customer Support');

INSERT INTO office.roles (id, code, name, description)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'employee', 'Employee', 'Can book workplaces for personal use'),
    (2, 'office_admin', 'Office administrator', 'Can manage floor plans, workplaces and unavailability'),
    (3, 'auditor', 'Auditor', 'Can view booking history and audit log');

INSERT INTO office.employees (
    id,
    email,
    last_name,
    first_name,
    middle_name,
    department_code,
    position_name
)
SELECT
    id,
    email,
    last_name,
    first_name,
    middle_name,
    department_code,
    position_name
FROM (
    VALUES
        (1, 'ivan.petrov@example.com', 'Petrov', 'Ivan', 'Petrovich', 'it', 'Backend Developer'),
        (2, 'anna.smirnova@example.com', 'Smirnova', 'Anna', 'Ivanovich', 'hr', 'HR Manager'),
        (3, 'pavel.ivanov@example.com', 'Ivanov', 'Pavel', 'Pavlovich', 'finance', 'Financial Analyst'),
        (4, 'olga.sokolova@example.com', 'Sokolova', 'Olga', 'Andreevich', 'sales', 'Sales Manager'),
        (5, 'maria.kuznetsova@example.com', 'Kuznetsova', 'Maria', 'Igorevich', 'product', 'QA Engineer')
) AS seed_employees(
    id,
    email,
    last_name,
    first_name,
    middle_name,
    department_code,
    position_name
)
UNION ALL
SELECT
    employee_number AS id,
    'employee' || lpad(employee_number::TEXT, 3, '0') || '@example.com' AS email,
    'Employee' AS last_name,
    lpad(employee_number::TEXT, 3, '0') AS first_name,
    (
        ARRAY[
            'Petrovich',
            'Ivanovich',
            'Pavlovich',
            'Andreevich',
            'Igorevich'
        ]
    )[1 + ((employee_number - 1) % 5)] AS middle_name,
    department_code,
    CASE department_code
        WHEN 'it' THEN 'Software Engineer'
        WHEN 'hr' THEN 'HR Specialist'
        WHEN 'finance' THEN 'Accountant'
        WHEN 'sales' THEN 'Account Manager'
        WHEN 'product' THEN 'Product Analyst'
        WHEN 'legal' THEN 'Legal Counsel'
        WHEN 'marketing' THEN 'Marketing Specialist'
        WHEN 'support' THEN 'Support Engineer'
    END AS position_name
FROM generate_series(6, 100) AS generated(employee_number)
CROSS JOIN LATERAL (
    SELECT (
        ARRAY[
            'it',
            'hr',
            'finance',
            'sales',
            'product',
            'legal',
            'marketing',
            'support'
        ]
    )[1 + ((employee_number - 1) % 8)] AS department_code
) departments;

INSERT INTO office.employee_roles (employee_id, role_code)
SELECT id, 'employee'
FROM office.employees
UNION
SELECT id, 'office_admin'
FROM office.employees
WHERE id IN (2, 15, 30, 45, 60, 75, 90)
UNION
SELECT id, 'auditor'
FROM office.employees
WHERE id IN (3, 20, 40, 80, 100);

SELECT setval(pg_get_serial_sequence('office.departments', 'id'), 8, true);
SELECT setval(pg_get_serial_sequence('office.roles', 'id'), 3, true);
