USE office_booking_profile;

SET @@explain_format = TREE;

EXPLAIN ANALYZE
WITH booked_workplaces AS (
    SELECT DISTINCT
        bx.workplace_id
    FROM bookings bx
    JOIN booking_statuses bsx ON bsx.id = bx.status_id
    WHERE bsx.code IN ('created', 'confirmed')
      AND bx.starts_at >= '2026-06-01 00:00:00'
      AND bx.starts_at < '2026-07-01 00:00:00'
),
zone_confirmed AS (
    SELECT
        w2.zone_id,
        COUNT(*) AS zone_confirmed_bookings
    FROM bookings b2
    JOIN workplaces w2 ON w2.id = b2.workplace_id
    JOIN booking_statuses bs2 ON bs2.id = b2.status_id
    WHERE bs2.code = 'confirmed'
      AND b2.starts_at >= '2026-06-01 00:00:00'
      AND b2.starts_at < '2026-07-01 00:00:00'
    GROUP BY w2.zone_id
)
SELECT
    o.code AS office_code,
    z.code AS zone_code,
    wt.code AS workplace_type,
    COUNT(DISTINCT w.id) AS active_workplaces,
    COUNT(b.id) AS bookings_count,
    SUM(bs.code = 'confirmed') AS confirmed_count,
    ROUND(SUM(TIMESTAMPDIFF(MINUTE, b.starts_at, b.ends_at)) / 60, 2) AS booked_hours,
    COALESCE(MAX(zc.zone_confirmed_bookings), 0) AS zone_confirmed_bookings
FROM offices o
JOIN zones z ON z.office_id = o.id
JOIN workplaces w ON w.zone_id = z.id
JOIN booked_workplaces bw ON bw.workplace_id = w.id
JOIN workplace_types wt ON wt.id = w.type_id
LEFT JOIN bookings b ON b.workplace_id = w.id
    AND b.starts_at >= '2026-06-01 00:00:00'
    AND b.starts_at < '2026-07-01 00:00:00'
LEFT JOIN booking_statuses bs ON bs.id = b.status_id
LEFT JOIN zone_confirmed zc ON zc.zone_id = z.id
WHERE w.is_active = 1
GROUP BY o.code, z.id, z.code, wt.code
HAVING bookings_count > 100
ORDER BY bookings_count DESC, booked_hours DESC
LIMIT 10;
