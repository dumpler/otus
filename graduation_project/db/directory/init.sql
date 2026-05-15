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

