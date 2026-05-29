USE office_booking_reports;

SELECT
    o.name AS office_name,
    CASE
        WHEN wt.code = 'meeting_room' THEN 'meeting'
        WHEN z.is_quiet_zone = 1 THEN 'quiet'
        ELSE 'open_space'
    END AS workplace_group,
    min(w.seats_count) AS min_seats,
    max(w.seats_count) AS max_seats,
    count(*) AS workplaces_count,
    sum(w.is_active = 1) AS active_workplaces_count
FROM workplaces w
JOIN zones z ON z.id = w.zone_id
JOIN offices o ON o.id = z.office_id
JOIN workplace_types wt ON wt.id = w.type_id
GROUP BY
    o.name,
    CASE
        WHEN wt.code = 'meeting_room' THEN 'meeting'
        WHEN z.is_quiet_zone = 1 THEN 'quiet'
        ELSE 'open_space'
    END
HAVING count(*) >= 2
ORDER BY office_name, workplace_group;

WITH ranked_workplaces AS (
    SELECT
        z.id AS zone_id,
        z.name AS zone_name,
        w.code AS workplace_code,
        w.name AS workplace_name,
        w.seats_count,
        row_number() OVER (
            PARTITION BY z.id
            ORDER BY w.seats_count DESC, w.code
        ) AS max_rank,
        row_number() OVER (
            PARTITION BY z.id
            ORDER BY w.seats_count ASC, w.code
        ) AS min_rank
    FROM workplaces w
    JOIN zones z ON z.id = w.zone_id
    WHERE w.is_active = 1
)
SELECT
    zone_name,
    max(CASE WHEN max_rank = 1 THEN workplace_code END) AS largest_workplace_code,
    max(CASE WHEN max_rank = 1 THEN workplace_name END) AS largest_workplace_name,
    max(CASE WHEN max_rank = 1 THEN seats_count END) AS max_seats,
    max(CASE WHEN min_rank = 1 THEN workplace_code END) AS smallest_workplace_code,
    max(CASE WHEN min_rank = 1 THEN workplace_name END) AS smallest_workplace_name,
    max(CASE WHEN min_rank = 1 THEN seats_count END) AS min_seats
FROM ranked_workplaces
GROUP BY zone_id, zone_name
ORDER BY zone_name;

SELECT
    IF(GROUPING(o.name), 'All offices', o.name) AS office_name,
    IF(GROUPING(z.name), 'All zones', z.name) AS zone_name,
    count(w.id) AS workplaces_count,
    sum(w.is_active = 1) AS active_workplaces_count
FROM offices o
JOIN zones z ON z.office_id = o.id
JOIN workplaces w ON w.zone_id = z.id
GROUP BY o.name, z.name WITH ROLLUP;

SELECT
    IF(GROUPING(o.name), 'All offices', o.name) AS office_name,
    IF(GROUPING(bs.code), 'All statuses', bs.code) AS booking_status,
    count(b.id) AS bookings_count
FROM bookings b
JOIN workplaces w ON w.id = b.workplace_id
JOIN zones z ON z.id = w.zone_id
JOIN offices o ON o.id = z.office_id
JOIN booking_statuses bs ON bs.id = b.status_id
GROUP BY o.name, bs.code WITH ROLLUP;
