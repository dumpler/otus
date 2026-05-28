SELECT
    id,
    email,
    last_name,
    first_name
FROM office.employees
WHERE email ~ '^[a-z]+\.[a-z]+@example\.com$'
ORDER BY id;

SELECT
    e.id,
    e.email,
    d.name AS department_name,
    er.role_code
FROM office.employees e
INNER JOIN office.departments d ON d.code = e.department_code
INNER JOIN office.employee_roles er ON er.employee_id = e.id
ORDER BY e.id, er.role_code;

SELECT
    e.id,
    e.email,
    d.name AS department_name,
    er.role_code
FROM office.employees e
LEFT JOIN office.departments d ON d.code = e.department_code
LEFT JOIN office.employee_roles er ON er.employee_id = e.id
ORDER BY e.id, er.role_code;

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

INSERT INTO office.employee_roles (employee_id, role_code)
VALUES (6, 'employee')
ON CONFLICT DO NOTHING;

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

DELETE FROM office.employee_roles er
USING office.employees e
WHERE e.id = er.employee_id
  AND e.email = 'sergey.orlov@example.com'
RETURNING
    er.employee_id,
    er.role_code;

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

SELECT
    code,
    name
FROM imported_departments
ORDER BY code;
