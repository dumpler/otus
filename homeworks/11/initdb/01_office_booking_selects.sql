CREATE DATABASE IF NOT EXISTS office_booking_selects
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE office_booking_selects;

CREATE TABLE IF NOT EXISTS departments (
    id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_departments_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS employees (
    id BIGINT UNSIGNED NOT NULL,
    email VARCHAR(255) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    department_id SMALLINT UNSIGNED,
    position_name VARCHAR(150) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_employees_email (email),
    KEY idx_employees_department (department_id),
    CONSTRAINT fk_employees_department
        FOREIGN KEY (department_id)
        REFERENCES departments (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS offices (
    id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    address VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_offices_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS workplaces (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    office_id SMALLINT UNSIGNED NOT NULL,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    has_monitor TINYINT(1) NOT NULL DEFAULT 0,
    has_docking_station TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_workplaces_office_code (office_id, code),
    KEY idx_workplaces_monitor (has_monitor, is_active),
    CONSTRAINT fk_workplaces_office
        FOREIGN KEY (office_id)
        REFERENCES offices (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS booking_statuses (
    id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    is_final TINYINT(1) NOT NULL DEFAULT 0,
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
    comment VARCHAR(255),
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_bookings_employee_period (employee_id, starts_at, ends_at),
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

INSERT IGNORE INTO departments (id, code, name)
VALUES
    (1, 'it', 'IT'),
    (2, 'hr', 'HR'),
    (3, 'finance', 'Finance'),
    (4, 'product', 'Product');

INSERT IGNORE INTO employees (
    id,
    email,
    last_name,
    first_name,
    middle_name,
    department_id,
    position_name,
    is_active
)
VALUES
    (1, 'ivan.petrov@example.com', 'Petrov', 'Ivan', 'Petrovich', 1, 'Backend Developer', 1),
    (2, 'anna.smirnova@example.com', 'Smirnova', 'Anna', 'Ivanovich', 2, 'HR Manager', 1),
    (3, 'pavel.ivanov@example.com', 'Ivanov', 'Pavel', 'Pavlovich', 3, 'Financial Analyst', 1),
    (4, 'maria.kuznetsova@example.com', 'Kuznetsova', 'Maria', 'Igorevich', 4, 'Product Manager', 1),
    (5, 'sergey.orlov@example.com', 'Orlov', 'Sergey', 'Andreevich', NULL, 'Contractor', 1),
    (6, 'olga.sokolova@example.com', 'Sokolova', 'Olga', 'Petrovich', 1, 'QA Engineer', 0);

INSERT IGNORE INTO offices (id, code, name, address)
VALUES
    (1, 'msk_main', 'Moscow Main Office', 'Moscow, Tverskaya street, 1');

INSERT IGNORE INTO workplaces (
    id,
    office_id,
    code,
    name,
    has_monitor,
    has_docking_station,
    is_active
)
VALUES
    (1, 1, 'A-501', 'Desk A-501', 1, 1, 1),
    (2, 1, 'A-502', 'Desk A-502', 1, 0, 1),
    (3, 1, 'Q-501', 'Focus room Q-501', 1, 1, 1),
    (4, 1, 'B-501', 'Desk B-501', 0, 0, 0);

INSERT IGNORE INTO booking_statuses (id, code, name, is_final)
VALUES
    (1, 'created', 'Created', 0),
    (2, 'confirmed', 'Confirmed', 0),
    (3, 'cancelled', 'Cancelled', 1),
    (4, 'completed', 'Completed', 1);

INSERT IGNORE INTO bookings (
    id,
    employee_id,
    workplace_id,
    status_id,
    starts_at,
    ends_at,
    comment,
    created_at
)
VALUES
    (1, 1, 1, 2, '2026-06-01 09:00:00.000000', '2026-06-01 18:00:00.000000', 'Regular office day', '2026-05-20 10:00:00.000000'),
    (2, 4, 3, 2, '2026-06-03 09:00:00.000000', '2026-06-03 18:00:00.000000', 'Quiet zone booking', '2026-05-21 11:00:00.000000'),
    (3, 1, 2, 3, '2026-06-04 09:00:00.000000', '2026-06-04 18:00:00.000000', 'Cancelled booking', '2026-05-22 12:00:00.000000'),
    (4, 3, 1, 4, '2026-05-25 09:00:00.000000', '2026-05-25 18:00:00.000000', 'Completed booking', '2026-05-10 09:00:00.000000');
