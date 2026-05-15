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

CREATE OR REPLACE FUNCTION audit.log_row_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO audit.change_log (
        schema_name,
        table_name,
        operation,
        row_pk,
        old_data,
        new_data
    )
    VALUES (
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        TG_OP,
        COALESCE((to_jsonb(NEW)->>'id'), (to_jsonb(OLD)->>'id')),
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) END
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE FUNCTION booking.log_booking_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' OR NEW.status_id IS DISTINCT FROM OLD.status_id THEN
        INSERT INTO booking.booking_status_history (
            booking_id,
            old_status_id,
            new_status_id,
            changed_by_employee_id
        )
        VALUES (
            NEW.id,
            CASE WHEN TG_OP = 'UPDATE' THEN OLD.status_id END,
            NEW.status_id,
            COALESCE(NEW.cancelled_by_employee_id, NEW.created_by_employee_id)
        );
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION booking.validate_booking()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    employee_is_active BOOLEAN;
    workplace_is_active BOOLEAN;
    booking_status_code TEXT;
BEGIN
    SELECT is_active
    INTO employee_is_active
    FROM office.employees
    WHERE id = NEW.employee_id;

    IF employee_is_active IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'Employee % is not active or does not exist', NEW.employee_id;
    END IF;

    SELECT w.is_active
    INTO workplace_is_active
    FROM office.workplaces w
    WHERE w.id = NEW.workplace_id;

    IF workplace_is_active IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'Workplace % is not active or does not exist', NEW.workplace_id;
    END IF;

    SELECT code
    INTO booking_status_code
    FROM booking.booking_statuses
    WHERE id = NEW.status_id;

    IF booking_status_code IN ('created', 'confirmed')
        AND EXISTS (
            SELECT 1
            FROM office.workplace_unavailability wu
            WHERE wu.workplace_id = NEW.workplace_id
              AND wu.unavailable_period && NEW.booked_period
        )
    THEN
        RAISE EXCEPTION 'Workplace % is unavailable for requested period', NEW.workplace_id;
    END IF;

    RETURN NEW;

END;
$$;

CREATE OR REPLACE FUNCTION office.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_departments_updated_at
BEFORE UPDATE ON office.departments
FOR EACH ROW EXECUTE FUNCTION office.set_updated_at();

CREATE TRIGGER trg_roles_updated_at
BEFORE UPDATE ON office.roles
FOR EACH ROW EXECUTE FUNCTION office.set_updated_at();

CREATE TRIGGER trg_offices_updated_at
BEFORE UPDATE ON office.offices
FOR EACH ROW EXECUTE FUNCTION office.set_updated_at();

CREATE TRIGGER trg_floors_updated_at
BEFORE UPDATE ON office.floors
FOR EACH ROW EXECUTE FUNCTION office.set_updated_at();

CREATE TRIGGER trg_zones_updated_at
BEFORE UPDATE ON office.zones
FOR EACH ROW EXECUTE FUNCTION office.set_updated_at();

CREATE TRIGGER trg_workplaces_updated_at
BEFORE UPDATE ON office.workplaces
FOR EACH ROW EXECUTE FUNCTION office.set_updated_at();

CREATE TRIGGER trg_floor_plans_updated_at
BEFORE UPDATE ON office.floor_plans
FOR EACH ROW EXECUTE FUNCTION office.set_updated_at();

CREATE TRIGGER trg_workplace_map_points_updated_at
BEFORE UPDATE ON office.workplace_map_points
FOR EACH ROW EXECUTE FUNCTION office.set_updated_at();

CREATE TRIGGER trg_bookings_updated_at
BEFORE UPDATE ON booking.bookings
FOR EACH ROW EXECUTE FUNCTION office.set_updated_at();

CREATE TRIGGER trg_bookings_validate
BEFORE INSERT OR UPDATE ON booking.bookings
FOR EACH ROW EXECUTE FUNCTION booking.validate_booking();

CREATE TRIGGER trg_bookings_status_history
AFTER INSERT OR UPDATE OF status_id ON booking.bookings
FOR EACH ROW EXECUTE FUNCTION booking.log_booking_status_change();

CREATE TRIGGER trg_bookings_audit
AFTER INSERT OR UPDATE OR DELETE ON booking.bookings
FOR EACH ROW EXECUTE FUNCTION audit.log_row_change();

CREATE TRIGGER trg_workplaces_audit
AFTER INSERT OR UPDATE OR DELETE ON office.workplaces
FOR EACH ROW EXECUTE FUNCTION audit.log_row_change();

CREATE TRIGGER trg_floor_plans_audit
AFTER INSERT OR UPDATE OR DELETE ON office.floor_plans
FOR EACH ROW EXECUTE FUNCTION audit.log_row_change();

CREATE TRIGGER trg_workplace_map_points_audit
AFTER INSERT OR UPDATE OR DELETE ON office.workplace_map_points
FOR EACH ROW EXECUTE FUNCTION audit.log_row_change();

CREATE INDEX idx_employees_department_code ON office.employees(department_code);
CREATE INDEX idx_employee_roles_role_code ON office.employee_roles(role_code);
CREATE INDEX idx_workplaces_zone_id ON office.workplaces(zone_id);
CREATE INDEX idx_floor_plans_floor_id ON office.floor_plans(floor_id);
CREATE INDEX idx_workplace_map_points_workplace_id ON office.workplace_map_points(workplace_id);
CREATE INDEX idx_bookings_employee_id ON booking.bookings(employee_id);
CREATE INDEX idx_bookings_workplace_period ON booking.bookings USING gist(workplace_id, booked_period);
CREATE INDEX idx_booking_history_booking_id ON booking.booking_status_history(booking_id);
CREATE INDEX idx_audit_change_log_table ON audit.change_log(schema_name, table_name, changed_at);

CREATE VIEW booking.active_bookings AS
SELECT
    b.id,
    e.full_name AS employee_name,
    e.email AS employee_email,
    o.name AS office_name,
    f.number AS floor_number,
    z.name AS zone_name,
    w.code AS workplace_code,
    lower(b.booked_period) AS starts_at,
    upper(b.booked_period) AS ends_at,
    bs.code AS status_code
FROM booking.bookings b
JOIN office.employees e ON e.id = b.employee_id
JOIN office.workplaces w ON w.id = b.workplace_id
JOIN office.zones z ON z.id = w.zone_id
JOIN office.floors f ON f.id = z.floor_id
JOIN office.offices o ON o.id = f.office_id
JOIN booking.booking_statuses bs ON bs.id = b.status_id
WHERE bs.code IN ('created', 'confirmed');

INSERT INTO office.workplace_types (code, name)
VALUES
    ('standard', 'Standard workplace'),
    ('standing_desk', 'Standing desk'),
    ('focus_room', 'Focus room');

INSERT INTO booking.booking_statuses (code, name, is_final)
VALUES
    ('created', 'Created', FALSE),
    ('confirmed', 'Confirmed', FALSE),
    ('cancelled', 'Cancelled', TRUE),
    ('completed', 'Completed', TRUE);

INSERT INTO booking.cancellation_reasons (code, name)
VALUES
    ('employee_cancelled', 'Cancelled by employee'),
    ('admin_cancelled', 'Cancelled by administrator'),
    ('workplace_unavailable', 'Workplace became unavailable');

INSERT INTO office.offices (code, name, city, address)
VALUES ('msk_main', 'Moscow Main Office', 'Moscow', 'Tverskaya street, 1');

INSERT INTO office.floors (office_id, number, name)
SELECT id, 5, 'Fifth floor'
FROM office.offices
WHERE code = 'msk_main';

INSERT INTO office.zones (floor_id, code, name, description, is_quiet_zone)
SELECT id, 'a', 'Open Space A', 'Main open space zone', FALSE
FROM office.floors
WHERE number = 5;

INSERT INTO office.zones (floor_id, code, name, description, is_quiet_zone)
SELECT id, 'q', 'Quiet Zone', 'Zone for focused work', TRUE
FROM office.floors
WHERE number = 5;

INSERT INTO office.workplaces (zone_id, type_id, code, name, has_monitor, has_docking_station)
SELECT z.id, wt.id, 'A-501', 'Desk A-501', TRUE, TRUE
FROM office.zones z
JOIN office.workplace_types wt ON wt.code = 'standard'
WHERE z.code = 'a';

INSERT INTO office.workplaces (zone_id, type_id, code, name, has_monitor, has_docking_station)
SELECT z.id, wt.id, 'A-502', 'Desk A-502', TRUE, FALSE
FROM office.zones z
JOIN office.workplace_types wt ON wt.code = 'standing_desk'
WHERE z.code = 'a';

INSERT INTO office.workplaces (zone_id, type_id, code, name, has_monitor, has_docking_station)
SELECT z.id, wt.id, 'Q-501', 'Focus room Q-501', TRUE, TRUE
FROM office.zones z
JOIN office.workplace_types wt ON wt.code = 'focus_room'
WHERE z.code = 'q';

INSERT INTO office.floor_plans (
    floor_id,
    version,
    file_name,
    svg_content,
    width_px,
    height_px
)
SELECT
    f.id,
    1,
    'msk-main-floor-5.svg',
    $svg$<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="650" viewBox="0 0 1000 650"><rect x="20" y="20" width="960" height="610" fill="#f8fafc" stroke="#334155" stroke-width="4"/><rect x="80" y="90" width="560" height="420" fill="#dbeafe" stroke="#1d4ed8" stroke-width="2"/><text x="100" y="125" font-family="Arial" font-size="24">Open Space A</text><rect x="700" y="90" width="220" height="420" fill="#dcfce7" stroke="#15803d" stroke-width="2"/><text x="720" y="125" font-family="Arial" font-size="24">Quiet Zone</text></svg>$svg$,
    1000,
    650
FROM office.floors f
JOIN office.offices o ON o.id = f.office_id
WHERE o.code = 'msk_main'
  AND f.number = 5;

INSERT INTO office.workplace_map_points (
    floor_plan_id,
    workplace_id,
    x_px,
    y_px,
    width_px,
    height_px,
    label
)
SELECT fp.id, w.id, point_data.x_px, point_data.y_px, 56, 42, w.code
FROM office.floor_plans fp
JOIN office.floors f ON f.id = fp.floor_id
JOIN office.zones z ON z.floor_id = f.id
JOIN office.workplaces w ON w.zone_id = z.id
JOIN (
    VALUES
        ('A-501', 180::NUMERIC, 220::NUMERIC),
        ('A-502', 300::NUMERIC, 220::NUMERIC),
        ('Q-501', 780::NUMERIC, 260::NUMERIC)
) AS point_data(workplace_code, x_px, y_px) ON point_data.workplace_code = w.code
WHERE fp.file_name = 'msk-main-floor-5.svg';
