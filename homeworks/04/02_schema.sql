SET ROLE office_booking_owner;

CREATE SCHEMA office AUTHORIZATION office_booking_owner;
CREATE SCHEMA booking AUTHORIZATION office_booking_owner;
CREATE SCHEMA audit AUTHORIZATION office_booking_owner;

CREATE TABLE office.departments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
) TABLESPACE office_core_ts;

CREATE TABLE office.employees (
    id BIGINT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    last_name TEXT NOT NULL,
    first_name TEXT NOT NULL,
    middle_name TEXT,
    department_code TEXT REFERENCES office.departments(code),
    position_name TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    source_updated_at TIMESTAMPTZ NOT NULL,
    replicated_at TIMESTAMPTZ NOT NULL DEFAULT now()
) TABLESPACE office_core_ts;

CREATE TABLE office.roles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
) TABLESPACE office_core_ts;

CREATE TABLE office.employee_roles (
    employee_id BIGINT NOT NULL REFERENCES office.employees(id) ON DELETE CASCADE,
    role_code TEXT NOT NULL REFERENCES office.roles(code),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (employee_id, role_code)
) TABLESPACE office_core_ts;

CREATE TABLE office.offices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    timezone TEXT NOT NULL DEFAULT 'Europe/Moscow',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
) TABLESPACE office_core_ts;

CREATE TABLE office.floors (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    office_id BIGINT NOT NULL REFERENCES office.offices(id),
    number INTEGER NOT NULL,
    name TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (office_id, number)
) TABLESPACE office_core_ts;

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
) TABLESPACE office_core_ts;

CREATE TABLE office.workplace_types (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL
) TABLESPACE office_core_ts;

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
) TABLESPACE office_core_ts;

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
    UNIQUE (floor_id, version)
) TABLESPACE office_core_ts;

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
    UNIQUE (floor_plan_id, workplace_id)
) TABLESPACE office_core_ts;

CREATE TABLE office.workplace_unavailability (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    workplace_id BIGINT NOT NULL REFERENCES office.workplaces(id),
    unavailable_period TSTZRANGE NOT NULL,
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
) TABLESPACE office_booking_ts;

CREATE TABLE booking.booking_statuses (
    id SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    is_final BOOLEAN NOT NULL DEFAULT FALSE
) TABLESPACE office_booking_ts;

CREATE TABLE booking.cancellation_reasons (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
) TABLESPACE office_booking_ts;

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
    cancelled_at TIMESTAMPTZ
) TABLESPACE office_booking_ts;

CREATE TABLE booking.booking_status_history (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES booking.bookings(id),
    old_status_id SMALLINT REFERENCES booking.booking_statuses(id),
    new_status_id SMALLINT NOT NULL REFERENCES booking.booking_statuses(id),
    changed_by_employee_id BIGINT REFERENCES office.employees(id),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
) TABLESPACE office_booking_ts;

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
) TABLESPACE office_audit_ts;

GRANT USAGE ON SCHEMA office, booking, audit TO office_booking_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA office, booking TO office_booking_app;
GRANT SELECT, INSERT ON audit.change_log TO office_booking_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA office, booking, audit TO office_booking_app;

GRANT USAGE ON SCHEMA office, booking, audit TO office_booking_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA office, booking, audit TO office_booking_readonly;
