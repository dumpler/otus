CREATE DATABASE IF NOT EXISTS office_booking_transactions
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE office_booking_transactions;

CREATE TABLE IF NOT EXISTS employees (
    id BIGINT UNSIGNED NOT NULL,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_employees_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS workplaces (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    last_booked_at DATETIME(6),
    PRIMARY KEY (id),
    UNIQUE KEY uq_workplaces_code (code)
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
    KEY idx_bookings_workplace_period (workplace_id, starts_at, ends_at),
    KEY idx_bookings_employee_period (employee_id, starts_at, ends_at),
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

CREATE TABLE IF NOT EXISTS booking_status_history (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    booking_id BIGINT UNSIGNED NOT NULL,
    old_status_id TINYINT UNSIGNED,
    new_status_id TINYINT UNSIGNED NOT NULL,
    changed_by_employee_id BIGINT UNSIGNED NOT NULL,
    changed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    KEY idx_booking_status_history_booking (booking_id),
    CONSTRAINT fk_booking_status_history_booking
        FOREIGN KEY (booking_id)
        REFERENCES bookings (id),
    CONSTRAINT fk_booking_status_history_old_status
        FOREIGN KEY (old_status_id)
        REFERENCES booking_statuses (id),
    CONSTRAINT fk_booking_status_history_new_status
        FOREIGN KEY (new_status_id)
        REFERENCES booking_statuses (id),
    CONSTRAINT fk_booking_status_history_changed_by
        FOREIGN KEY (changed_by_employee_id)
        REFERENCES employees (id)
) ENGINE=InnoDB;

INSERT IGNORE INTO employees (id, email, full_name, is_active)
VALUES
    (1, 'ivan.petrov@example.com', 'Ivan Petrov Petrovich', 1),
    (2, 'maria.kuznetsova@example.com', 'Maria Kuznetsova Igorevich', 1);

INSERT IGNORE INTO workplaces (id, code, name, is_active)
VALUES
    (1, 'A-501', 'Desk A-501', 1),
    (2, 'Q-501', 'Focus room Q-501', 1);

INSERT IGNORE INTO booking_statuses (id, code, name, is_final)
VALUES
    (1, 'created', 'Created', 0),
    (2, 'confirmed', 'Confirmed', 0),
    (3, 'cancelled', 'Cancelled', 1);

DROP PROCEDURE IF EXISTS create_confirmed_booking;

DELIMITER //

CREATE PROCEDURE create_confirmed_booking(
    IN p_employee_id BIGINT UNSIGNED,
    IN p_workplace_id BIGINT UNSIGNED,
    IN p_starts_at DATETIME(6),
    IN p_ends_at DATETIME(6),
    IN p_comment VARCHAR(255)
)
BEGIN
    DECLARE v_booking_id BIGINT UNSIGNED;
    DECLARE v_confirmed_status_id TINYINT UNSIGNED;
    DECLARE v_active_employee_count INT DEFAULT 0;
    DECLARE v_active_workplace_count INT DEFAULT 0;
    DECLARE v_overlap_count INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_starts_at >= p_ends_at THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Booking start time must be earlier than end time';
    END IF;

    SELECT count(*)
    INTO v_active_employee_count
    FROM employees
    WHERE id = p_employee_id
      AND is_active = 1
    FOR UPDATE;

    IF v_active_employee_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Employee is not active or does not exist';
    END IF;

    SELECT count(*)
    INTO v_active_workplace_count
    FROM workplaces
    WHERE id = p_workplace_id
      AND is_active = 1
    FOR UPDATE;

    IF v_active_workplace_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Workplace is not active or does not exist';
    END IF;

    SELECT id
    INTO v_confirmed_status_id
    FROM booking_statuses
    WHERE code = 'confirmed';

    SELECT count(*)
    INTO v_overlap_count
    FROM bookings
    WHERE workplace_id = p_workplace_id
      AND status_id = v_confirmed_status_id
      AND starts_at < p_ends_at
      AND ends_at > p_starts_at
    FOR UPDATE;

    IF v_overlap_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Workplace already has confirmed booking for requested period';
    END IF;

    INSERT INTO bookings (
        employee_id,
        workplace_id,
        status_id,
        starts_at,
        ends_at,
        comment
    )
    VALUES (
        p_employee_id,
        p_workplace_id,
        v_confirmed_status_id,
        p_starts_at,
        p_ends_at,
        p_comment
    );

    SET v_booking_id = LAST_INSERT_ID();

    INSERT INTO booking_status_history (
        booking_id,
        old_status_id,
        new_status_id,
        changed_by_employee_id
    )
    VALUES (
        v_booking_id,
        NULL,
        v_confirmed_status_id,
        p_employee_id
    );

    UPDATE workplaces
    SET last_booked_at = CURRENT_TIMESTAMP(6)
    WHERE id = p_workplace_id;

    COMMIT;

    SELECT
        v_booking_id AS booking_id;
END//

DELIMITER ;
