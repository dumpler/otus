CREATE DATABASE IF NOT EXISTS office_booking_cluster
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE office_booking_cluster;

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

INSERT INTO offices (id, code, name)
VALUES
    (1, 'msk_main', 'Moscow Main Office'),
    (2, 'spb_center', 'Saint Petersburg Center'),
    (3, 'kzn_center', 'Kazan Center');

INSERT INTO workplaces (id, office_id, code, name, is_active)
VALUES
    (1, 1, 'A-501', 'Desk A-501', 1),
    (2, 1, 'Q-501', 'Focus room Q-501', 1),
    (3, 2, 'B-401', 'Desk B-401', 1),
    (4, 3, 'K-301', 'Desk K-301', 1);
