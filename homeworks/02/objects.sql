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

ALTER TABLE office.employees
ADD CONSTRAINT chk_employees_email_format
CHECK (email LIKE '%_@_%._%');

ALTER TABLE office.employees
ADD CONSTRAINT chk_employees_name_not_blank
CHECK (
    btrim(last_name) <> ''
    AND btrim(first_name) <> ''
);

ALTER TABLE office.offices
ADD CONSTRAINT chk_offices_address_not_blank
CHECK (btrim(address) <> '');

ALTER TABLE office.workplaces
ADD CONSTRAINT chk_workplaces_code_not_blank
CHECK (btrim(code) <> '');

ALTER TABLE office.workplace_unavailability
ADD CONSTRAINT chk_workplace_unavailability_reason_not_blank
CHECK (btrim(reason) <> '');

ALTER TABLE office.floor_plans
ADD CONSTRAINT chk_floor_plans_dimensions_positive
CHECK (
    width_px > 0
    AND height_px > 0
);

ALTER TABLE office.floor_plans
ADD CONSTRAINT chk_floor_plans_svg_content
CHECK (svg_content LIKE '%<svg%');

ALTER TABLE office.workplace_map_points
ADD CONSTRAINT chk_workplace_map_points_coordinates
CHECK (
    x_px >= 0
    AND y_px >= 0
    AND width_px > 0
    AND height_px > 0
);

ALTER TABLE booking.bookings
ADD CONSTRAINT chk_bookings_period
CHECK (lower(booked_period) < upper(booked_period));

ALTER TABLE booking.bookings
ADD CONSTRAINT chk_bookings_cancellation_fields
CHECK (
    (cancelled_at IS NULL AND cancellation_reason_id IS NULL)
    OR (cancelled_at IS NOT NULL AND cancellation_reason_id IS NOT NULL)
);

ALTER TABLE booking.bookings
ADD CONSTRAINT ex_bookings_no_workplace_period_overlap
EXCLUDE USING gist (
    workplace_id WITH =,
    booked_period WITH &&
) WHERE (status_id IN (1, 2));

ALTER TABLE office.workplace_unavailability
ADD CONSTRAINT chk_workplace_unavailability_period
CHECK (lower(unavailable_period) < upper(unavailable_period));

ALTER TABLE office.workplace_unavailability
ADD CONSTRAINT ex_workplace_unavailability_no_period_overlap
EXCLUDE USING gist (
    workplace_id WITH =,
    unavailable_period WITH &&
);

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
    concat_ws(' ', e.last_name, e.first_name, e.middle_name) AS employee_name,
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
