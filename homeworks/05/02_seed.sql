INSERT INTO office.departments (id, code, name)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'it', 'IT'),
    (2, 'hr', 'HR'),
    (3, 'finance', 'Finance'),
    (4, 'sales', 'Sales'),
    (5, 'product', 'Product')
ON CONFLICT (code) DO NOTHING;

INSERT INTO office.roles (id, code, name, description)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'employee', 'Employee', 'Can book workplaces for personal use'),
    (2, 'office_admin', 'Office administrator', 'Can manage offices and workplaces'),
    (3, 'auditor', 'Auditor', 'Can view booking history')
ON CONFLICT (code) DO NOTHING;

INSERT INTO office.employees (
    id,
    email,
    last_name,
    first_name,
    middle_name,
    department_code,
    position_name,
    is_active
)
VALUES
    (1, 'ivan.petrov@example.com', 'Petrov', 'Ivan', 'Petrovich', 'it', 'Backend Developer', TRUE),
    (2, 'anna.smirnova@example.com', 'Smirnova', 'Anna', 'Ivanovich', 'hr', 'HR Manager', TRUE),
    (3, 'pavel.ivanov@example.com', 'Ivanov', 'Pavel', 'Pavlovich', 'finance', 'Financial Analyst', TRUE),
    (4, 'olga.sokolova@example.com', 'Sokolova', 'Olga', 'Andreevich', 'sales', 'Sales Manager', TRUE),
    (5, 'maria.kuznetsova@example.com', 'Kuznetsova', 'Maria', 'Igorevich', 'product', 'QA Engineer', TRUE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO office.employee_roles (employee_id, role_code)
VALUES
    (1, 'employee'),
    (2, 'employee'),
    (2, 'office_admin'),
    (3, 'employee'),
    (3, 'auditor'),
    (4, 'employee'),
    (5, 'employee')
ON CONFLICT DO NOTHING;

INSERT INTO office.offices (id, code, name, address)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'msk_main', 'Moscow Main Office', 'Moscow, Tverskaya street, 1')
ON CONFLICT (code) DO NOTHING;

INSERT INTO office.floors (id, office_id, number, name)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 5, 'Fifth floor')
ON CONFLICT (office_id, number) DO NOTHING;

INSERT INTO office.zones (id, floor_id, code, name, description, is_quiet_zone)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 'a', 'Open Space A', 'Main open space zone', FALSE),
    (2, 1, 'q', 'Quiet Zone', 'Zone for focused work', TRUE)
ON CONFLICT (floor_id, code) DO NOTHING;

INSERT INTO office.workplace_types (id, code, name)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'standard', 'Standard workplace'),
    (2, 'standing_desk', 'Standing desk'),
    (3, 'focus_room', 'Focus room')
ON CONFLICT (code) DO NOTHING;

INSERT INTO office.workplaces (
    id,
    zone_id,
    type_id,
    code,
    name,
    has_monitor,
    has_docking_station
)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 1, 'A-501', 'Desk A-501', TRUE, TRUE),
    (2, 1, 2, 'A-502', 'Desk A-502', TRUE, FALSE),
    (3, 2, 3, 'Q-501', 'Focus room Q-501', TRUE, TRUE)
ON CONFLICT (zone_id, code) DO NOTHING;

INSERT INTO booking.booking_statuses (id, code, name, is_final)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'created', 'Created', FALSE),
    (2, 'confirmed', 'Confirmed', FALSE),
    (3, 'cancelled', 'Cancelled', TRUE),
    (4, 'completed', 'Completed', TRUE)
ON CONFLICT (code) DO NOTHING;

INSERT INTO booking.bookings (
    employee_id,
    workplace_id,
    status_id,
    booked_period,
    comment,
    created_by_employee_id
)
VALUES
    (1, 1, 2, tstzrange('2026-06-01 09:00:00+03', '2026-06-01 18:00:00+03', '[)'), 'Regular office day', 1),
    (5, 3, 2, tstzrange('2026-06-03 09:00:00+03', '2026-06-03 18:00:00+03', '[)'), 'Quiet zone booking', 5);
