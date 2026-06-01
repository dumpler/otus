USE office_booking_routines;

DROP PROCEDURE IF EXISTS get_workplaces;
DROP PROCEDURE IF EXISTS get_orders;
DROP TRIGGER IF EXISTS trg_bookings_before_insert_no_overlap;
DROP TRIGGER IF EXISTS trg_bookings_after_insert_audit;

DELIMITER //

CREATE PROCEDURE get_workplaces(
    IN p_office_code VARCHAR(32),
    IN p_zone_code VARCHAR(32),
    IN p_workplace_type_code VARCHAR(32),
    IN p_min_seats TINYINT UNSIGNED,
    IN p_max_seats TINYINT UNSIGNED,
    IN p_has_monitor TINYINT,
    IN p_only_active TINYINT,
    IN p_sort_by VARCHAR(32),
    IN p_sort_direction VARCHAR(4),
    IN p_limit INT UNSIGNED,
    IN p_offset INT UNSIGNED
)
BEGIN
    SELECT
        w.id,
        w.code,
        w.name,
        o.name AS office_name,
        z.name AS zone_name,
        wt.name AS workplace_type,
        w.seats_count,
        w.has_monitor,
        w.is_active
    FROM workplaces w
    JOIN zones z ON z.id = w.zone_id
    JOIN offices o ON o.id = z.office_id
    JOIN workplace_types wt ON wt.id = w.type_id
    WHERE (p_office_code IS NULL OR o.code = p_office_code)
      AND (p_zone_code IS NULL OR z.code = p_zone_code)
      AND (p_workplace_type_code IS NULL OR wt.code = p_workplace_type_code)
      AND (p_min_seats IS NULL OR w.seats_count >= p_min_seats)
      AND (p_max_seats IS NULL OR w.seats_count <= p_max_seats)
      AND (p_has_monitor IS NULL OR w.has_monitor = p_has_monitor)
      AND (p_only_active IS NULL OR p_only_active = 0 OR w.is_active = 1)
    ORDER BY
        CASE WHEN LOWER(p_sort_by) = 'code' AND LOWER(p_sort_direction) = 'asc' THEN w.code END ASC,
        CASE WHEN LOWER(p_sort_by) = 'code' AND LOWER(p_sort_direction) = 'desc' THEN w.code END DESC,
        CASE WHEN LOWER(p_sort_by) = 'name' AND LOWER(p_sort_direction) = 'asc' THEN w.name END ASC,
        CASE WHEN LOWER(p_sort_by) = 'name' AND LOWER(p_sort_direction) = 'desc' THEN w.name END DESC,
        CASE WHEN LOWER(p_sort_by) = 'office' AND LOWER(p_sort_direction) = 'asc' THEN o.name END ASC,
        CASE WHEN LOWER(p_sort_by) = 'office' AND LOWER(p_sort_direction) = 'desc' THEN o.name END DESC,
        CASE WHEN LOWER(p_sort_by) = 'zone' AND LOWER(p_sort_direction) = 'asc' THEN z.name END ASC,
        CASE WHEN LOWER(p_sort_by) = 'zone' AND LOWER(p_sort_direction) = 'desc' THEN z.name END DESC,
        CASE WHEN LOWER(p_sort_by) = 'seats' AND LOWER(p_sort_direction) = 'asc' THEN w.seats_count END ASC,
        CASE WHEN LOWER(p_sort_by) = 'seats' AND LOWER(p_sort_direction) = 'desc' THEN w.seats_count END DESC,
        w.code ASC
    LIMIT p_limit OFFSET p_offset;
END //

CREATE PROCEDURE get_orders(
    IN p_period_from DATETIME,
    IN p_period_to DATETIME,
    IN p_period_step VARCHAR(16),
    IN p_group_by VARCHAR(32)
)
BEGIN
    SELECT
        CASE
            WHEN p_period_step = 'hour' THEN DATE_FORMAT(b.starts_at, '%Y-%m-%d %H:00:00')
            WHEN p_period_step = 'week' THEN DATE_FORMAT(DATE_SUB(DATE(b.starts_at), INTERVAL WEEKDAY(b.starts_at) DAY), '%Y-%m-%d')
            ELSE DATE_FORMAT(DATE(b.starts_at), '%Y-%m-%d')
        END AS period_start,
        CASE
            WHEN p_group_by = 'workplace' THEN w.code
            WHEN p_group_by = 'zone' THEN z.code
            WHEN p_group_by = 'office' THEN o.code
            WHEN p_group_by = 'type' THEN wt.code
            WHEN p_group_by = 'status' THEN bs.code
            ELSE 'all'
        END AS group_value,
        COUNT(*) AS bookings_count,
        SUM(bs.code = 'confirmed') AS confirmed_count,
        SUM(bs.code = 'cancelled') AS cancelled_count,
        ROUND(SUM(TIMESTAMPDIFF(MINUTE, b.starts_at, b.ends_at)) / 60, 2) AS booked_hours
    FROM bookings b
    JOIN workplaces w ON w.id = b.workplace_id
    JOIN workplace_types wt ON wt.id = w.type_id
    JOIN zones z ON z.id = w.zone_id
    JOIN offices o ON o.id = z.office_id
    JOIN booking_statuses bs ON bs.id = b.status_id
    WHERE b.starts_at >= p_period_from
      AND b.starts_at < p_period_to
    GROUP BY period_start, group_value
    ORDER BY period_start, group_value;
END //

CREATE TRIGGER trg_bookings_before_insert_no_overlap
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM bookings b
        JOIN booking_statuses bs ON bs.id = b.status_id
        WHERE b.workplace_id = NEW.workplace_id
          AND bs.code IN ('created', 'confirmed')
          AND NEW.starts_at < b.ends_at
          AND NEW.ends_at > b.starts_at
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Workplace already has active booking for this period';
    END IF;
END //

CREATE TRIGGER trg_bookings_after_insert_audit
AFTER INSERT ON bookings
FOR EACH ROW
BEGIN
    INSERT INTO booking_audit (booking_id, action_type, details)
    VALUES (
        NEW.id,
        'insert',
        CONCAT('Booking created for workplace ', NEW.workplace_id)
    );
END //

DELIMITER ;

GRANT EXECUTE ON PROCEDURE office_booking_routines.get_workplaces TO 'client'@'%';
GRANT EXECUTE ON PROCEDURE office_booking_routines.get_orders TO 'manager'@'%';
FLUSH PRIVILEGES;
