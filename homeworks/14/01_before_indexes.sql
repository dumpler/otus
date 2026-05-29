USE office_booking_indexes;

EXPLAIN
SELECT
    id,
    workplace_id,
    status_id,
    starts_at,
    ends_at
FROM bookings
WHERE workplace_id = 42
  AND status_id = 2
  AND starts_at >= '2026-06-01 00:00:00'
ORDER BY starts_at
LIMIT 10;

SELECT
    id,
    workplace_id,
    status_id,
    starts_at,
    ends_at
FROM bookings
WHERE workplace_id = 42
  AND status_id = 2
  AND starts_at >= '2026-06-01 00:00:00'
ORDER BY starts_at
LIMIT 10;

EXPLAIN
SELECT
    id,
    code,
    name,
    description
FROM workplaces
WHERE name LIKE '%quiet%'
   OR description LIKE '%quiet%'
   OR properties LIKE '%quiet%'
ORDER BY id
LIMIT 10;

SELECT
    id,
    code,
    name,
    description
FROM workplaces
WHERE name LIKE '%quiet%'
   OR description LIKE '%quiet%'
   OR properties LIKE '%quiet%'
ORDER BY id
LIMIT 10;
