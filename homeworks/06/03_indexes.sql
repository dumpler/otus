CREATE INDEX idx_bookings_employee_id
ON booking.bookings (employee_id);

CREATE INDEX idx_bookings_workplace_status_created
ON booking.bookings (workplace_id, status_id, created_at DESC);

CREATE INDEX idx_bookings_comment_fts
ON booking.bookings
USING GIN (to_tsvector('english', coalesce(comment, '')));

CREATE INDEX idx_employees_lower_email
ON office.employees (lower(email));

CREATE INDEX idx_workplaces_active_monitor
ON office.workplaces (zone_id, code)
WHERE is_active = TRUE
  AND has_monitor = TRUE;

COMMENT ON INDEX booking.idx_bookings_employee_id IS 'Ускоряет поиск бронирований конкретного сотрудника';
COMMENT ON INDEX booking.idx_bookings_workplace_status_created IS 'Ускоряет поиск последних бронирований рабочего места по статусу';
COMMENT ON INDEX booking.idx_bookings_comment_fts IS 'Ускоряет полнотекстовый поиск по комментариям к бронированиям';
COMMENT ON INDEX office.idx_employees_lower_email IS 'Ускоряет поиск сотрудника по email без учета регистра';
COMMENT ON INDEX office.idx_workplaces_active_monitor IS 'Ускоряет поиск активных рабочих мест с монитором внутри зоны';

ANALYZE office.employees;
ANALYZE office.workplaces;
ANALYZE booking.bookings;

EXPLAIN (COSTS OFF)
SELECT
    id,
    workplace_id,
    booked_period
FROM booking.bookings
WHERE employee_id = 42;

EXPLAIN (COSTS OFF)
SELECT
    id,
    employee_id,
    created_at
FROM booking.bookings
WHERE workplace_id = 15
  AND status_id = 2
ORDER BY created_at DESC
LIMIT 10;

EXPLAIN (COSTS OFF)
SELECT
    id,
    comment
FROM booking.bookings
WHERE to_tsvector('english', coalesce(comment, '')) @@ plainto_tsquery('english', 'quiet monitor');

EXPLAIN (COSTS OFF)
SELECT
    id,
    email,
    last_name,
    first_name
FROM office.employees
WHERE lower(email) = lower('EMPLOYEE420@example.com');

EXPLAIN (COSTS OFF)
SELECT
    id,
    code,
    name
FROM office.workplaces
WHERE zone_id = 2
  AND is_active = TRUE
  AND has_monitor = TRUE
ORDER BY code;
