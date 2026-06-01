CREATE DATABASE IF NOT EXISTS office_booking_profile
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE office_booking_profile;

CREATE TABLE departments (
    id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_departments_code (code)
) ENGINE=InnoDB;

CREATE TABLE employees (
    id BIGINT UNSIGNED NOT NULL,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    department_id SMALLINT UNSIGNED NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_employees_email (email),
    CONSTRAINT fk_employees_department
        FOREIGN KEY (department_id)
        REFERENCES departments (id)
) ENGINE=InnoDB;

CREATE TABLE offices (
    id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_offices_code (code)
) ENGINE=InnoDB;

CREATE TABLE zones (
    id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    office_id SMALLINT UNSIGNED NOT NULL,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    is_quiet_zone TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uq_zones_office_code (office_id, code),
    CONSTRAINT fk_zones_office
        FOREIGN KEY (office_id)
        REFERENCES offices (id)
) ENGINE=InnoDB;

CREATE TABLE workplace_types (
    id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_workplace_types_code (code)
) ENGINE=InnoDB;

CREATE TABLE workplaces (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    zone_id SMALLINT UNSIGNED NOT NULL,
    type_id TINYINT UNSIGNED NOT NULL,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    seats_count TINYINT UNSIGNED NOT NULL DEFAULT 1,
    has_monitor TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_workplaces_zone_code (zone_id, code),
    CONSTRAINT fk_workplaces_zone
        FOREIGN KEY (zone_id)
        REFERENCES zones (id),
    CONSTRAINT fk_workplaces_type
        FOREIGN KEY (type_id)
        REFERENCES workplace_types (id),
    CONSTRAINT chk_workplaces_seats_count
        CHECK (seats_count > 0)
) ENGINE=InnoDB;

CREATE TABLE booking_statuses (
    id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    is_final TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uq_booking_statuses_code (code)
) ENGINE=InnoDB;

CREATE TABLE bookings (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    employee_id BIGINT UNSIGNED NOT NULL,
    workplace_id BIGINT UNSIGNED NOT NULL,
    status_id TINYINT UNSIGNED NOT NULL,
    starts_at DATETIME(6) NOT NULL,
    ends_at DATETIME(6) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT fk_bookings_employee
        FOREIGN KEY (employee_id)
        REFERENCES employees (id),
    CONSTRAINT fk_bookings_workplace
        FOREIGN KEY (workplace_id)
        REFERENCES workplaces (id),
    CONSTRAINT fk_bookings_status
        FOREIGN KEY (status_id)
        REFERENCES booking_statuses (id),
    CONSTRAINT chk_bookings_period
        CHECK (starts_at < ends_at)
) ENGINE=InnoDB;

INSERT INTO departments (id, code, name)
VALUES
    (1, 'it', 'IT'),
    (2, 'hr', 'HR'),
    (3, 'finance', 'Finance'),
    (4, 'product', 'Product');

INSERT INTO offices (id, code, name)
VALUES
    (1, 'msk_main', 'Moscow Main Office'),
    (2, 'spb_center', 'Saint Petersburg Center');

INSERT INTO zones (id, office_id, code, name, is_quiet_zone)
VALUES
    (1, 1, 'open_a', 'Open Space A', 0),
    (2, 1, 'quiet_a', 'Quiet Zone A', 1),
    (3, 1, 'meeting_a', 'Meeting Zone A', 0),
    (4, 2, 'open_b', 'Open Space B', 0),
    (5, 2, 'quiet_b', 'Quiet Zone B', 1),
    (6, 2, 'meeting_b', 'Meeting Zone B', 0);

INSERT INTO workplace_types (id, code, name)
VALUES
    (1, 'standard', 'Standard workplace'),
    (2, 'focus_room', 'Focus room'),
    (3, 'meeting_room', 'Meeting room');

INSERT INTO booking_statuses (id, code, name, is_final)
VALUES
    (1, 'created', 'Created', 0),
    (2, 'confirmed', 'Confirmed', 0),
    (3, 'cancelled', 'Cancelled', 1),
    (4, 'completed', 'Completed', 1);

SET SESSION cte_max_recursion_depth = 12000;

INSERT INTO employees (
    id,
    email,
    full_name,
    department_id,
    is_active
)
SELECT
    gs,
    CONCAT('employee', gs, '@example.com'),
    CONCAT('Employee ', gs),
    1 + (gs % 4),
    IF(gs % 25 = 0, 0, 1)
FROM (
    WITH RECURSIVE seq(gs) AS (
        SELECT 1
        UNION ALL
        SELECT gs + 1
        FROM seq
        WHERE gs < 2000
    )
    SELECT gs
    FROM seq
) seq_rows;

INSERT INTO workplaces (
    id,
    zone_id,
    type_id,
    code,
    name,
    seats_count,
    has_monitor,
    is_active
)
SELECT
    gs,
    1 + (gs % 6),
    CASE
        WHEN gs % 17 = 0 THEN 3
        WHEN gs % 7 = 0 THEN 2
        ELSE 1
    END,
    CONCAT('W-', LPAD(gs, 5, '0')),
    CASE
        WHEN gs % 17 = 0 THEN CONCAT('Meeting room ', gs)
        WHEN gs % 7 = 0 THEN CONCAT('Focus room ', gs)
        ELSE CONCAT('Desk ', gs)
    END,
    CASE
        WHEN gs % 17 = 0 THEN 4 + (gs % 8)
        ELSE 1
    END,
    IF(gs % 3 = 0 OR gs % 17 = 0, 1, 0),
    IF(gs % 29 = 0, 0, 1)
FROM (
    WITH RECURSIVE seq(gs) AS (
        SELECT 1
        UNION ALL
        SELECT gs + 1
        FROM seq
        WHERE gs < 3000
    )
    SELECT gs
    FROM seq
) seq_rows;

INSERT INTO bookings (
    employee_id,
    workplace_id,
    status_id,
    starts_at,
    ends_at,
    created_at
)
SELECT
    1 + (gs % 2000),
    1 + (gs % 3000),
    CASE
        WHEN gs % 17 = 0 THEN 3
        WHEN gs % 11 = 0 THEN 4
        WHEN gs % 5 = 0 THEN 1
        ELSE 2
    END,
    TIMESTAMP('2026-05-01 09:00:00') + INTERVAL (gs % 90) DAY,
    TIMESTAMP('2026-05-01 18:00:00') + INTERVAL (gs % 90) DAY,
    TIMESTAMP('2026-04-01 09:00:00') + INTERVAL gs MINUTE
FROM (
    WITH RECURSIVE seq(gs) AS (
        SELECT 1
        UNION ALL
        SELECT gs + 1
        FROM seq
        WHERE gs < 12000
    )
    SELECT gs
    FROM seq
) seq_rows;

CREATE VIEW v_zone_booking_profile AS
SELECT
    o.code AS office_code,
    z.code AS zone_code,
    wt.code AS workplace_type,
    COUNT(DISTINCT w.id) AS active_workplaces,
    COUNT(b.id) AS bookings_count,
    SUM(bs.code = 'confirmed') AS confirmed_count,
    ROUND(SUM(TIMESTAMPDIFF(MINUTE, b.starts_at, b.ends_at)) / 60, 2) AS booked_hours,
    (
        SELECT COUNT(*)
        FROM bookings b2
        JOIN workplaces w2 ON w2.id = b2.workplace_id
        JOIN booking_statuses bs2 ON bs2.id = b2.status_id
        WHERE w2.zone_id = z.id
          AND bs2.code = 'confirmed'
          AND b2.starts_at >= '2026-06-01 00:00:00'
          AND b2.starts_at < '2026-07-01 00:00:00'
    ) AS zone_confirmed_bookings
FROM offices o
JOIN zones z ON z.office_id = o.id
JOIN workplaces w ON w.zone_id = z.id
JOIN workplace_types wt ON wt.id = w.type_id
LEFT JOIN bookings b ON b.workplace_id = w.id
    AND b.starts_at >= '2026-06-01 00:00:00'
    AND b.starts_at < '2026-07-01 00:00:00'
LEFT JOIN booking_statuses bs ON bs.id = b.status_id
WHERE w.is_active = 1
  AND EXISTS (
      SELECT 1
      FROM bookings bx
      JOIN booking_statuses bsx ON bsx.id = bx.status_id
      WHERE bx.workplace_id = w.id
        AND bsx.code IN ('created', 'confirmed')
        AND bx.starts_at >= '2026-06-01 00:00:00'
        AND bx.starts_at < '2026-07-01 00:00:00'
  )
GROUP BY o.code, z.id, z.code, wt.code
HAVING bookings_count > 100
ORDER BY bookings_count DESC, booked_hours DESC
LIMIT 10;
