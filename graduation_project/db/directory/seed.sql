INSERT INTO office.departments (id, code, name)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'it', 'IT'),
    (2, 'hr', 'HR'),
    (3, 'finance', 'Finance'),
    (4, 'sales', 'Sales');

INSERT INTO office.roles (id, code, name, description)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'employee', 'Employee', 'Can book workplaces for personal use'),
    (2, 'office_admin', 'Office administrator', 'Can manage floor plans, workplaces and unavailability'),
    (3, 'auditor', 'Auditor', 'Can view booking history and audit log');

INSERT INTO office.employees (
    id,
    external_id,
    email,
    full_name,
    department_code,
    position_name
)
VALUES
    (1, 'ad-1001', 'ivan.petrov@example.com', 'Ivan Petrov', 'it', 'Backend Developer'),
    (2, 'ad-1002', 'anna.smirnova@example.com', 'Anna Smirnova', 'hr', 'HR Manager'),
    (3, 'ad-1003', 'pavel.ivanov@example.com', 'Pavel Ivanov', 'finance', 'Financial Analyst'),
    (4, 'ad-1004', 'olga.sokolova@example.com', 'Olga Sokolova', 'sales', 'Sales Manager');

INSERT INTO office.employee_roles (employee_id, role_code)
VALUES
    (1, 'employee'),
    (2, 'employee'),
    (2, 'office_admin'),
    (3, 'auditor'),
    (4, 'employee');

SELECT setval(pg_get_serial_sequence('office.departments', 'id'), 4, true);
SELECT setval(pg_get_serial_sequence('office.roles', 'id'), 3, true);

