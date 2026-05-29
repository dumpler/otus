USE office_booking_indexes;

EXPLAIN
SELECT
    id,
    workplace_id,
    status_id,
    starts_at,
    ends_at
FROM bookings
FORCE INDEX (idx_bookings_workplace_status_start)
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
FORCE INDEX (idx_bookings_workplace_status_start)
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
    description,
    MATCH(name, description, properties) AGAINST('quiet focus monitor') AS relevance
FROM workplaces
WHERE MATCH(name, description, properties) AGAINST('quiet focus monitor')
ORDER BY relevance DESC
LIMIT 10;

SELECT
    id,
    code,
    name,
    description,
    MATCH(name, description, properties) AGAINST('quiet focus monitor') AS relevance
FROM workplaces
WHERE MATCH(name, description, properties) AGAINST('quiet focus monitor')
ORDER BY relevance DESC
LIMIT 10;
