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
SELECT
    gs,
    'employee' || gs || '@example.com',
    CASE gs % 5
        WHEN 0 THEN 'Petrov'
        WHEN 1 THEN 'Ivanov'
        WHEN 2 THEN 'Sokolov'
        WHEN 3 THEN 'Smirnov'
        ELSE 'Kuznetsov'
    END,
    CASE gs % 5
        WHEN 0 THEN 'Ivan'
        WHEN 1 THEN 'Pavel'
        WHEN 2 THEN 'Sergey'
        WHEN 3 THEN 'Andrey'
        ELSE 'Igor'
    END,
    CASE gs % 5
        WHEN 0 THEN 'Petrovich'
        WHEN 1 THEN 'Ivanovich'
        WHEN 2 THEN 'Pavlovich'
        WHEN 3 THEN 'Andreevich'
        ELSE 'Igorevich'
    END,
    CASE gs % 5
        WHEN 0 THEN 'it'
        WHEN 1 THEN 'hr'
        WHEN 2 THEN 'finance'
        WHEN 3 THEN 'sales'
        ELSE 'product'
    END,
    CASE gs % 5
        WHEN 0 THEN 'Backend Developer'
        WHEN 1 THEN 'HR Manager'
        WHEN 2 THEN 'Financial Analyst'
        WHEN 3 THEN 'Sales Manager'
        ELSE 'Product Manager'
    END,
    gs % 20 <> 0
FROM generate_series(1, 5000) AS gs
ON CONFLICT (id) DO NOTHING;

INSERT INTO office.employee_roles (employee_id, role_code)
SELECT id, 'employee'
FROM office.employees
ON CONFLICT DO NOTHING;

INSERT INTO office.employee_roles (employee_id, role_code)
SELECT id, 'office_admin'
FROM office.employees
WHERE id % 250 = 0
ON CONFLICT DO NOTHING;

INSERT INTO office.offices (id, code, name, address)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'msk_main', 'Moscow Main Office', 'Moscow, Tverskaya street, 1')
ON CONFLICT (code) DO NOTHING;

INSERT INTO office.floors (id, office_id, number, name)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 5, 'Fifth floor'),
    (2, 1, 6, 'Sixth floor')
ON CONFLICT (office_id, number) DO NOTHING;

INSERT INTO office.zones (id, floor_id, code, name, description, is_quiet_zone)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 'a', 'Open Space A', 'Main open space zone', FALSE),
    (2, 1, 'q', 'Quiet Zone', 'Zone for focused work', TRUE),
    (3, 2, 'b', 'Open Space B', 'Second open space zone', FALSE),
    (4, 2, 'm', 'Meeting Zone', 'Meeting and collaboration zone', FALSE)
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
    has_docking_station,
    is_active
)
OVERRIDING SYSTEM VALUE
SELECT
    gs,
    ((gs - 1) % 4) + 1,
    ((gs - 1) % 3) + 1,
    'W-' || lpad(gs::TEXT, 4, '0'),
    'Workplace W-' || lpad(gs::TEXT, 4, '0'),
    gs % 2 = 0,
    gs % 3 = 0,
    gs % 25 <> 0
FROM generate_series(1, 5000) AS gs
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
    created_by_employee_id,
    created_at
)
SELECT
    ((gs - 1) % 5000) + 1,
    ((gs - 1) % 5000) + 1,
    CASE
        WHEN gs % 17 = 0 THEN 3
        WHEN gs % 11 = 0 THEN 4
        WHEN gs % 5 = 0 THEN 1
        ELSE 2
    END,
    tstzrange(
        TIMESTAMPTZ '2026-06-01 09:00:00+03' + ((gs % 60) * INTERVAL '1 day'),
        TIMESTAMPTZ '2026-06-01 18:00:00+03' + ((gs % 60) * INTERVAL '1 day'),
        '[)'
    ),
    CASE
        WHEN gs % 13 = 0 THEN 'Need quiet focus workplace with monitor'
        WHEN gs % 7 = 0 THEN 'Regular office booking'
        WHEN gs % 5 = 0 THEN 'Team meeting preparation'
        ELSE 'Office day'
    END,
    ((gs - 1) % 5000) + 1,
    TIMESTAMPTZ '2026-05-01 09:00:00+03' + (gs * INTERVAL '1 minute')
FROM generate_series(1, 30000) AS gs;

ANALYZE office.employees;
ANALYZE office.workplaces;
ANALYZE booking.bookings;
