SET NAMES utf8mb4;

USE office_booking_transactions;

CALL create_confirmed_booking(
    1,
    1,
    '2026-06-10 09:00:00.000000',
    '2026-06-10 18:00:00.000000',
    'Office day from stored procedure'
);

SELECT
    b.id,
    e.email,
    w.code AS workplace_code,
    bs.code AS status_code,
    b.starts_at,
    b.ends_at,
    b.comment
FROM bookings b
JOIN employees e ON e.id = b.employee_id
JOIN workplaces w ON w.id = b.workplace_id
JOIN booking_statuses bs ON bs.id = b.status_id
ORDER BY b.id;

SELECT
    h.booking_id,
    h.old_status_id,
    h.new_status_id,
    h.changed_by_employee_id,
    h.changed_at
FROM booking_status_history h
ORDER BY h.id;

SELECT
    id,
    code,
    last_booked_at
FROM workplaces
ORDER BY id;
