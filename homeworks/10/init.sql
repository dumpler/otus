CREATE DATABASE IF NOT EXISTS office_booking_types
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE office_booking_types;

CREATE TABLE IF NOT EXISTS departments (
    id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_departments_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS employees (
    id BIGINT UNSIGNED NOT NULL,
    email VARCHAR(255) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    department_id SMALLINT UNSIGNED NOT NULL,
    position_name VARCHAR(150) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    source_updated_at DATETIME(6) NOT NULL,
    replicated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
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
    timezone VARCHAR(64) NOT NULL DEFAULT 'Europe/Moscow',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_offices_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS workplace_types (
    id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_workplace_types_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS workplaces (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    office_id SMALLINT UNSIGNED NOT NULL,
    type_id TINYINT UNSIGNED NOT NULL,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    has_monitor TINYINT(1) NOT NULL DEFAULT 0,
    has_docking_station TINYINT(1) NOT NULL DEFAULT 0,
    attributes JSON NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_workplaces_office_code (office_id, code),
    KEY idx_workplaces_type (type_id),
    KEY idx_workplaces_monitor_count ((CAST(JSON_UNQUOTE(JSON_EXTRACT(attributes, '$.equipment.monitors')) AS UNSIGNED))),
    CONSTRAINT fk_workplaces_office
        FOREIGN KEY (office_id)
        REFERENCES offices (id),
    CONSTRAINT fk_workplaces_type
        FOREIGN KEY (type_id)
        REFERENCES workplace_types (id)
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
    client_context JSON NOT NULL,
    created_by_employee_id BIGINT UNSIGNED,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_bookings_employee_period (employee_id, starts_at, ends_at),
    KEY idx_bookings_workplace_period (workplace_id, starts_at, ends_at),
    KEY idx_bookings_source ((CAST(JSON_UNQUOTE(JSON_EXTRACT(client_context, '$.source')) AS CHAR(32)))),
    CONSTRAINT fk_bookings_employee
        FOREIGN KEY (employee_id)
        REFERENCES employees (id),
    CONSTRAINT fk_bookings_workplace
        FOREIGN KEY (workplace_id)
        REFERENCES workplaces (id),
    CONSTRAINT fk_bookings_status
        FOREIGN KEY (status_id)
        REFERENCES booking_statuses (id),
    CONSTRAINT fk_bookings_created_by
        FOREIGN KEY (created_by_employee_id)
        REFERENCES employees (id),
    CONSTRAINT chk_bookings_period
        CHECK (starts_at < ends_at)
) ENGINE=InnoDB;

INSERT IGNORE INTO departments (id, code, name)
VALUES
    (1, 'it', 'IT'),
    (2, 'product', 'Product');

INSERT IGNORE INTO employees (
    id,
    email,
    last_name,
    first_name,
    middle_name,
    department_id,
    position_name,
    source_updated_at
)
VALUES
    (1, 'ivan.petrov@example.com', 'Petrov', 'Ivan', 'Petrovich', 1, 'Backend Developer', '2026-05-29 10:00:00.000000'),
    (2, 'maria.kuznetsova@example.com', 'Kuznetsova', 'Maria', 'Igorevich', 2, 'Product Manager', '2026-05-29 10:00:00.000000');

INSERT IGNORE INTO offices (id, code, name, address)
VALUES
    (1, 'msk_main', 'Moscow Main Office', 'Moscow, Tverskaya street, 1');

INSERT IGNORE INTO workplace_types (id, code, name)
VALUES
    (1, 'standard', 'Standard workplace'),
    (2, 'focus_room', 'Focus room');

INSERT IGNORE INTO workplaces (
    id,
    office_id,
    type_id,
    code,
    name,
    has_monitor,
    has_docking_station,
    attributes
)
VALUES
    (
        1,
        1,
        1,
        'A-501',
        'Desk A-501',
        1,
        1,
        JSON_OBJECT(
            'equipment',
            JSON_OBJECT('monitors', 2, 'dock', TRUE, 'keyboard', 'en'),
            'accessibility',
            JSON_OBJECT('wheelchair', TRUE),
            'tags',
            JSON_ARRAY('window', 'team')
        )
    ),
    (
        2,
        1,
        2,
        'Q-501',
        'Focus room Q-501',
        1,
        1,
        JSON_OBJECT(
            'equipment',
            JSON_OBJECT('monitors', 1, 'dock', TRUE, 'webcam', TRUE),
            'accessibility',
            JSON_OBJECT('wheelchair', FALSE),
            'tags',
            JSON_ARRAY('quiet', 'focus')
        )
    );

INSERT IGNORE INTO booking_statuses (id, code, name, is_final)
VALUES
    (1, 'created', 'Created', 0),
    (2, 'confirmed', 'Confirmed', 0),
    (3, 'cancelled', 'Cancelled', 1);

INSERT IGNORE INTO bookings (
    id,
    employee_id,
    workplace_id,
    status_id,
    starts_at,
    ends_at,
    comment,
    client_context,
    created_by_employee_id
)
VALUES
    (
        1,
        1,
        1,
        2,
        '2026-06-01 09:00:00.000000',
        '2026-06-01 18:00:00.000000',
        'Regular office day',
        JSON_OBJECT('source', 'web', 'user_agent', 'Firefox', 'filters', JSON_OBJECT('monitor', TRUE, 'quiet', FALSE)),
        1
    ),
    (
        2,
        2,
        2,
        2,
        '2026-06-03 09:00:00.000000',
        '2026-06-03 18:00:00.000000',
        'Quiet zone booking',
        JSON_OBJECT('source', 'mobile', 'app_version', '1.4.2', 'filters', JSON_OBJECT('monitor', TRUE, 'quiet', TRUE)),
        2
    );
