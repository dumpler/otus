CREATE DATABASE IF NOT EXISTS office_booking_mysql
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE office_booking_mysql;

CREATE TABLE IF NOT EXISTS departments (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_departments_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS employees (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    department_id BIGINT UNSIGNED NOT NULL,
    position_name VARCHAR(150) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_employees_email (email),
    KEY idx_employees_department (department_id),
    CONSTRAINT fk_employees_department
        FOREIGN KEY (department_id)
        REFERENCES departments (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS offices (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    address VARCHAR(255) NOT NULL,
    timezone VARCHAR(64) NOT NULL DEFAULT 'Europe/Moscow',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id),
    UNIQUE KEY uq_offices_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS workplaces (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    office_id BIGINT UNSIGNED NOT NULL,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    has_monitor BOOLEAN NOT NULL DEFAULT FALSE,
    has_docking_station BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id),
    UNIQUE KEY uq_workplaces_office_code (office_id, code),
    CONSTRAINT fk_workplaces_office
        FOREIGN KEY (office_id)
        REFERENCES offices (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS bookings (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    employee_id BIGINT UNSIGNED NOT NULL,
    workplace_id BIGINT UNSIGNED NOT NULL,
    starts_at DATETIME NOT NULL,
    ends_at DATETIME NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'created',
    comment VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_bookings_employee_period (employee_id, starts_at, ends_at),
    KEY idx_bookings_workplace_period (workplace_id, starts_at, ends_at),
    CONSTRAINT fk_bookings_employee
        FOREIGN KEY (employee_id)
        REFERENCES employees (id),
    CONSTRAINT fk_bookings_workplace
        FOREIGN KEY (workplace_id)
        REFERENCES workplaces (id),
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
    position_name
)
VALUES
    (1, 'ivan.petrov@example.com', 'Petrov', 'Ivan', 'Petrovich', 1, 'Backend Developer'),
    (2, 'anna.smirnova@example.com', 'Smirnova', 'Anna', 'Ivanovich', 2, 'HR Manager'),
    (3, 'pavel.ivanov@example.com', 'Ivanov', 'Pavel', 'Pavlovich', 3, 'Financial Analyst'),
    (4, 'maria.kuznetsova@example.com', 'Kuznetsova', 'Maria', 'Igorevich', 4, 'Product Manager');

INSERT IGNORE INTO offices (id, code, name, address)
VALUES
    (1, 'msk_main', 'Moscow Main Office', 'Moscow, Tverskaya street, 1');

INSERT IGNORE INTO workplaces (
    id,
    office_id,
    code,
    name,
    has_monitor,
    has_docking_station
)
VALUES
    (1, 1, 'A-501', 'Desk A-501', TRUE, TRUE),
    (2, 1, 'A-502', 'Desk A-502', TRUE, FALSE),
    (3, 1, 'Q-501', 'Focus room Q-501', TRUE, TRUE);

INSERT IGNORE INTO bookings (
    id,
    employee_id,
    workplace_id,
    starts_at,
    ends_at,
    status,
    comment
)
VALUES
    (1, 1, 1, '2026-06-01 09:00:00', '2026-06-01 18:00:00', 'confirmed', 'Regular office day'),
    (2, 4, 3, '2026-06-03 09:00:00', '2026-06-03 18:00:00', 'confirmed', 'Quiet zone booking');
