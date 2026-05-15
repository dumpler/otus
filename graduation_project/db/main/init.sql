CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE SCHEMA IF NOT EXISTS office;
CREATE SCHEMA IF NOT EXISTS booking;
CREATE SCHEMA IF NOT EXISTS audit;

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
    source_updated_at TIMESTAMPTZ NOT NULL,
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
    city TEXT NOT NULL,
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

CREATE TABLE office.floor_plans (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    floor_id BIGINT NOT NULL REFERENCES office.floors(id),
    version INTEGER NOT NULL DEFAULT 1,
    file_name TEXT NOT NULL,
    svg_content TEXT NOT NULL,
    width_px INTEGER NOT NULL,
    height_px INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (floor_id, version),
    CHECK (width_px > 0),
    CHECK (height_px > 0),
    CHECK (svg_content LIKE '%<svg%')
);

CREATE TABLE office.workplace_map_points (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    floor_plan_id BIGINT NOT NULL REFERENCES office.floor_plans(id) ON DELETE CASCADE,
    workplace_id BIGINT NOT NULL REFERENCES office.workplaces(id),
    x_px NUMERIC(10, 2) NOT NULL,
    y_px NUMERIC(10, 2) NOT NULL,
    width_px NUMERIC(10, 2) NOT NULL DEFAULT 32,
    height_px NUMERIC(10, 2) NOT NULL DEFAULT 32,
    rotation_deg NUMERIC(6, 2) NOT NULL DEFAULT 0,
    label TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (floor_plan_id, workplace_id),
    CHECK (x_px >= 0),
    CHECK (y_px >= 0),
    CHECK (width_px > 0),
    CHECK (height_px > 0)
);

CREATE TABLE booking.booking_statuses (
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    is_final BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE booking.cancellation_reasons (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE booking.bookings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES office.employees(id),
    workplace_id BIGINT NOT NULL REFERENCES office.workplaces(id),
    status_id SMALLINT NOT NULL REFERENCES booking.booking_statuses(id),
    cancellation_reason_id BIGINT REFERENCES booking.cancellation_reasons(id),
    booked_period TSTZRANGE NOT NULL,
    comment TEXT,
    created_by_employee_id BIGINT REFERENCES office.employees(id),
    cancelled_by_employee_id BIGINT REFERENCES office.employees(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    cancelled_at TIMESTAMPTZ,
    CHECK (lower(booked_period) < upper(booked_period)),
    CHECK (
        (cancelled_at IS NULL AND cancellation_reason_id IS NULL)
        OR (cancelled_at IS NOT NULL AND cancellation_reason_id IS NOT NULL)
    ),
    EXCLUDE USING gist (
        workplace_id WITH =,
        booked_period WITH &&
    ) WHERE (status_id IN (1, 2))
);

CREATE TABLE booking.booking_status_history (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES booking.bookings(id),
    old_status_id SMALLINT REFERENCES booking.booking_statuses(id),
    new_status_id SMALLINT NOT NULL REFERENCES booking.booking_statuses(id),
    changed_by_employee_id BIGINT REFERENCES office.employees(id),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE office.workplace_unavailability (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    workplace_id BIGINT NOT NULL REFERENCES office.workplaces(id),
    unavailable_period TSTZRANGE NOT NULL,
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (lower(unavailable_period) < upper(unavailable_period)),
    EXCLUDE USING gist (
        workplace_id WITH =,
        unavailable_period WITH &&
    )
);

CREATE TABLE audit.change_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL,
    row_pk TEXT,
    old_data JSONB,
    new_data JSONB,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    changed_by TEXT NOT NULL DEFAULT current_user
);

