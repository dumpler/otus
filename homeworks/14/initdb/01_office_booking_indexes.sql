CREATE DATABASE IF NOT EXISTS office_booking_indexes
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE office_booking_indexes;

CREATE TABLE IF NOT EXISTS departments (
    id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_departments_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS employees (
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

CREATE TABLE IF NOT EXISTS offices (
    id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_offices_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS zones (
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

CREATE TABLE IF NOT EXISTS workplaces (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    zone_id SMALLINT UNSIGNED NOT NULL,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    description TEXT NOT NULL,
    properties TEXT NOT NULL,
    has_monitor TINYINT(1) NOT NULL DEFAULT 0,
    has_docking_station TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_workplaces_zone_code (zone_id, code),
    CONSTRAINT fk_workplaces_zone
        FOREIGN KEY (zone_id)
        REFERENCES zones (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS booking_statuses (
    id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_booking_statuses_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS bookings (
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
    (3, 2, 'open_b', 'Open Space B', 0),
    (4, 2, 'quiet_b', 'Quiet Zone B', 1);

INSERT INTO booking_statuses (id, code, name)
VALUES
    (1, 'created', 'Created'),
    (2, 'confirmed', 'Confirmed'),
    (3, 'cancelled', 'Cancelled'),
    (4, 'completed', 'Completed');

SET SESSION cte_max_recursion_depth = 30000;

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
        WHERE gs < 5000
    )
    SELECT gs
    FROM seq
) seq_rows;

INSERT INTO workplaces (
    id,
    zone_id,
    code,
    name,
    description,
    properties,
    has_monitor,
    has_docking_station,
    is_active
)
SELECT
    gs,
    1 + (gs % 4),
    CONCAT('W-', LPAD(gs, 5, '0')),
    CASE
        WHEN gs % 17 = 0 THEN CONCAT('Quiet focus workplace ', gs)
        WHEN gs % 11 = 0 THEN CONCAT('Meeting workplace ', gs)
        ELSE CONCAT('Standard workplace ', gs)
    END,
    CASE
        WHEN gs % 17 = 0 THEN 'Quiet focus desk with monitor for concentrated work'
        WHEN gs % 11 = 0 THEN 'Collaboration workplace near meeting room'
        ELSE 'Regular office workplace'
    END,
    CASE
        WHEN gs % 17 = 0 THEN 'quiet focus monitor window ergonomic'
        WHEN gs % 11 = 0 THEN 'meeting collaboration whiteboard monitor'
        ELSE 'standard desk office'
    END,
    IF(gs % 3 = 0 OR gs % 17 = 0, 1, 0),
    IF(gs % 5 = 0, 1, 0),
    IF(gs % 29 = 0, 0, 1)
FROM (
    WITH RECURSIVE seq(gs) AS (
        SELECT 1
        UNION ALL
        SELECT gs + 1
        FROM seq
        WHERE gs < 8000
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
    1 + (gs % 5000),
    1 + (gs % 8000),
    CASE
        WHEN gs % 17 = 0 THEN 3
        WHEN gs % 11 = 0 THEN 4
        WHEN gs % 5 = 0 THEN 1
        ELSE 2
    END,
    TIMESTAMP('2026-06-01 09:00:00') + INTERVAL (gs % 60) DAY,
    TIMESTAMP('2026-06-01 18:00:00') + INTERVAL (gs % 60) DAY,
    TIMESTAMP('2026-05-01 09:00:00') + INTERVAL gs MINUTE
FROM (
    WITH RECURSIVE seq(gs) AS (
        SELECT 1
        UNION ALL
        SELECT gs + 1
        FROM seq
        WHERE gs < 30000
    )
    SELECT gs
    FROM seq
) seq_rows;
