USE office_booking_replication;

INSERT INTO offices (code, name)
VALUES ('kzn_center', 'Kazan Center');

INSERT INTO workplaces (office_id, code, name, is_active)
VALUES (3, 'K-301', 'Desk K-301', 1);

INSERT INTO bookings (workplace_id, employee_email, starts_at, ends_at, status_code)
VALUES (4, 'anna.smirnova@example.com', '2026-06-03 10:00:00', '2026-06-03 12:00:00', 'confirmed');

INSERT INTO audit_log (event_text)
VALUES ('this table is ignored by replica');

USE office_booking_ignore;

INSERT INTO ignored_events (event_text)
VALUES ('this database is ignored by replica after replication start');
