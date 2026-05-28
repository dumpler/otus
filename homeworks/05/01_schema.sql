CREATE SCHEMA IF NOT EXISTS office;
CREATE SCHEMA IF NOT EXISTS booking;

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
    email TEXT NOT NULL UNIQUE,
    last_name TEXT NOT NULL,
    first_name TEXT NOT NULL,
    middle_name TEXT,
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

CREATE TABLE office.offices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    timezone TEXT NOT NULL DEFAULT 'Europe/Moscow',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE office.floors (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    office_id BIGINT NOT NULL REFERENCES office.offices(id),
    number INTEGER NOT NULL,
    name TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (office_id, number)
);

CREATE TABLE office.zones (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    floor_id BIGINT NOT NULL REFERENCES office.floors(id),
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_quiet_zone BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (floor_id, code)
);

CREATE TABLE office.workplace_types (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL
);

CREATE TABLE office.workplaces (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    zone_id BIGINT NOT NULL REFERENCES office.zones(id),
    type_id BIGINT NOT NULL REFERENCES office.workplace_types(id),
    code TEXT NOT NULL,
    name TEXT,
    has_monitor BOOLEAN NOT NULL DEFAULT FALSE,
    has_docking_station BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (zone_id, code)
);

CREATE TABLE booking.booking_statuses (
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    is_final BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE booking.bookings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES office.employees(id),
    workplace_id BIGINT NOT NULL REFERENCES office.workplaces(id),
    status_id SMALLINT NOT NULL REFERENCES booking.booking_statuses(id),
    booked_period TSTZRANGE NOT NULL,
    comment TEXT,
    created_by_employee_id BIGINT REFERENCES office.employees(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
