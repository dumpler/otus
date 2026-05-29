USE office_booking_selects;

SELECT
    b.id,
    e.email,
    w.code AS workplace_code,
    bs.code AS status_code,
    b.starts_at,
    b.ends_at
FROM bookings b
INNER JOIN employees e ON e.id = b.employee_id
INNER JOIN workplaces w ON w.id = b.workplace_id
INNER JOIN booking_statuses bs ON bs.id = b.status_id
ORDER BY b.starts_at;

SELECT
    e.id,
    e.email,
    e.position_name,
    d.name AS department_name
FROM employees e
LEFT JOIN departments d ON d.id = e.department_id
ORDER BY e.id;

SELECT
    id,
    email,
    position_name
FROM employees
WHERE is_active = 1
ORDER BY id;

SELECT
    id,
    workplace_id,
    starts_at,
    ends_at
FROM bookings
WHERE starts_at BETWEEN '2026-06-01 00:00:00' AND '2026-06-07 23:59:59'
ORDER BY starts_at;

SELECT
    id,
    email,
    department_id
FROM employees
WHERE department_id IN (1, 4)
ORDER BY id;

SELECT
    id,
    email,
    last_name
FROM employees
WHERE email LIKE '%@example.com'
ORDER BY email;

SELECT
    id,
    code,
    name
FROM workplaces
WHERE has_monitor = 1
  AND is_active = 1
ORDER BY code;
