CREATE SCHEMA IF NOT EXISTS office;

CREATE TABLE office.departments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE office.employees (
    id BIGINT PRIMARY KEY,
    external_id TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    department_code TEXT REFERENCES office.departments(code),
    position_name TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    source_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    replicated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE office.roles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE office.employee_roles (
    employee_id BIGINT NOT NULL REFERENCES office.employees(id) ON DELETE CASCADE,
    role_code TEXT NOT NULL REFERENCES office.roles(code),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (employee_id, role_code)
);

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

CREATE PUBLICATION directory_roles_publication
FOR TABLE office.roles;

CREATE PUBLICATION directory_departments_publication
FOR TABLE office.departments;

CREATE PUBLICATION directory_employees_publication
FOR TABLE office.employees;

CREATE PUBLICATION directory_employee_roles_publication
FOR TABLE office.employee_roles;
