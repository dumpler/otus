CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'repl_pass';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';

CREATE DATABASE IF NOT EXISTS office_booking_replication
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS office_booking_ignore
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE office_booking_replication;

CREATE TABLE offices (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_offices_code (code)
) ENGINE=InnoDB;

CREATE TABLE workplaces (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    office_id BIGINT UNSIGNED NOT NULL,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_workplaces_office_code (office_id, code),
    CONSTRAINT fk_workplaces_office
        FOREIGN KEY (office_id)
        REFERENCES offices (id)
) ENGINE=InnoDB;

CREATE TABLE bookings (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    workplace_id BIGINT UNSIGNED NOT NULL,
    employee_email VARCHAR(255) NOT NULL,
    starts_at DATETIME NOT NULL,
    ends_at DATETIME NOT NULL,
    status_code VARCHAR(32) NOT NULL,
    PRIMARY KEY (id),
    KEY idx_bookings_workplace_start (workplace_id, starts_at),
    CONSTRAINT fk_bookings_workplace
        FOREIGN KEY (workplace_id)
        REFERENCES workplaces (id),
    CONSTRAINT chk_bookings_period
        CHECK (starts_at < ends_at)
) ENGINE=InnoDB;

CREATE TABLE audit_log (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    event_text VARCHAR(255) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

INSERT INTO offices (id, code, name)
VALUES
    (1, 'msk_main', 'Moscow Main Office'),
    (2, 'spb_center', 'Saint Petersburg Center');

INSERT INTO workplaces (id, office_id, code, name, is_active)
VALUES
    (1, 1, 'A-501', 'Desk A-501', 1),
    (2, 1, 'Q-501', 'Focus room Q-501', 1),
    (3, 2, 'B-401', 'Desk B-401', 1);

INSERT INTO bookings (id, workplace_id, employee_email, starts_at, ends_at, status_code)
VALUES
    (1, 1, 'ivan.petrov@example.com', '2026-06-01 09:00:00', '2026-06-01 18:00:00', 'confirmed'),
    (2, 2, 'maria.kuznetsova@example.com', '2026-06-02 09:00:00', '2026-06-02 18:00:00', 'created');

INSERT INTO audit_log (event_text)
VALUES
    ('initial audit event');

USE office_booking_ignore;

CREATE TABLE ignored_events (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    event_text VARCHAR(255) NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

INSERT INTO ignored_events (event_text)
VALUES
    ('this database is ignored by replica');
