CREATE DATABASE IF NOT EXISTS office_booking_routines
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE office_booking_routines;

CREATE TABLE offices (
    id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    address VARCHAR(255) NOT NULL,
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
    KEY idx_workplaces_zone_type (zone_id, type_id),
    CONSTRAINT fk_workplaces_zone
        FOREIGN KEY (zone_id)
        REFERENCES zones (id),
    CONSTRAINT fk_workplaces_type
        FOREIGN KEY (type_id)
        REFERENCES workplace_types (id),
    CONSTRAINT chk_workplaces_seats_count
        CHECK (seats_count > 0)
) ENGINE=InnoDB;

CREATE TABLE employees (
    id BIGINT UNSIGNED NOT NULL,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_employees_email (email)
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
    KEY idx_bookings_workplace_period (workplace_id, starts_at, ends_at),
    KEY idx_bookings_status_start (status_id, starts_at),
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

CREATE TABLE booking_audit (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    booking_id BIGINT UNSIGNED NOT NULL,
    action_type VARCHAR(32) NOT NULL,
    action_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    details VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    KEY idx_booking_audit_booking (booking_id),
    CONSTRAINT fk_booking_audit_booking
        FOREIGN KEY (booking_id)
        REFERENCES bookings (id)
) ENGINE=InnoDB;

INSERT INTO offices (id, code, name, address)
VALUES
    (1, 'msk_main', 'Moscow Main Office', 'Moscow, Tverskaya street, 1'),
    (2, 'spb_center', 'Saint Petersburg Center', 'Saint Petersburg, Nevsky prospect, 10');

INSERT INTO zones (id, office_id, code, name, is_quiet_zone)
VALUES
    (1, 1, 'open_a', 'Open Space A', 0),
    (2, 1, 'quiet_a', 'Quiet Zone A', 1),
    (3, 1, 'meeting_a', 'Meeting Zone A', 0),
    (4, 2, 'open_b', 'Open Space B', 0),
    (5, 2, 'quiet_b', 'Quiet Zone B', 1);

INSERT INTO workplace_types (id, code, name)
VALUES
    (1, 'standard', 'Standard workplace'),
    (2, 'focus_room', 'Focus room'),
    (3, 'meeting_room', 'Meeting room');

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
VALUES
    (1, 1, 1, 'A-501', 'Desk A-501', 1, 1, 1),
    (2, 1, 1, 'A-502', 'Desk A-502', 1, 1, 1),
    (3, 1, 1, 'A-503', 'Desk A-503', 1, 0, 0),
    (4, 2, 2, 'Q-501', 'Focus room Q-501', 1, 1, 1),
    (5, 2, 2, 'Q-502', 'Focus room Q-502', 1, 1, 1),
    (6, 3, 3, 'M-501', 'Meeting room M-501', 6, 1, 1),
    (7, 3, 3, 'M-502', 'Meeting room M-502', 10, 1, 1),
    (8, 4, 1, 'B-401', 'Desk B-401', 1, 1, 1),
    (9, 4, 1, 'B-402', 'Desk B-402', 1, 0, 1),
    (10, 5, 2, 'Q-401', 'Focus room Q-401', 1, 1, 1);

INSERT INTO employees (id, email, full_name)
VALUES
    (1, 'ivan.petrov@example.com', 'Ivan Petrov Petrovich'),
    (2, 'maria.kuznetsova@example.com', 'Maria Kuznetsova Igorevich'),
    (3, 'pavel.ivanov@example.com', 'Pavel Ivanov Pavlovich'),
    (4, 'anna.smirnova@example.com', 'Anna Smirnova Ivanovich');

INSERT INTO booking_statuses (id, code, name, is_final)
VALUES
    (1, 'created', 'Created', 0),
    (2, 'confirmed', 'Confirmed', 0),
    (3, 'cancelled', 'Cancelled', 1),
    (4, 'completed', 'Completed', 1);

INSERT INTO bookings (
    id,
    employee_id,
    workplace_id,
    status_id,
    starts_at,
    ends_at,
    created_at
)
VALUES
    (1, 1, 1, 2, '2026-06-01 09:00:00.000000', '2026-06-01 18:00:00.000000', '2026-05-20 10:00:00.000000'),
    (2, 2, 4, 2, '2026-06-01 09:00:00.000000', '2026-06-01 18:00:00.000000', '2026-05-20 10:05:00.000000'),
    (3, 3, 6, 2, '2026-06-01 10:00:00.000000', '2026-06-01 12:00:00.000000', '2026-05-20 10:10:00.000000'),
    (4, 1, 2, 3, '2026-06-02 09:00:00.000000', '2026-06-02 18:00:00.000000', '2026-05-21 09:00:00.000000'),
    (5, 4, 7, 2, '2026-06-02 11:00:00.000000', '2026-06-02 13:00:00.000000', '2026-05-21 09:10:00.000000'),
    (6, 2, 8, 2, '2026-06-03 09:00:00.000000', '2026-06-03 18:00:00.000000', '2026-05-22 09:00:00.000000'),
    (7, 3, 9, 4, '2026-06-03 09:00:00.000000', '2026-06-03 18:00:00.000000', '2026-05-22 09:05:00.000000'),
    (8, 4, 10, 2, '2026-06-04 09:00:00.000000', '2026-06-04 18:00:00.000000', '2026-05-23 09:00:00.000000'),
    (9, 1, 5, 3, '2026-06-05 09:00:00.000000', '2026-06-05 18:00:00.000000', '2026-05-24 09:00:00.000000'),
    (10, 2, 6, 4, '2026-06-05 10:00:00.000000', '2026-06-05 12:00:00.000000', '2026-05-24 09:10:00.000000');
