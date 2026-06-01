SELECT @@server_id AS server_id, @@gtid_mode AS gtid_mode;

SHOW BINARY LOG STATUS;

USE office_booking_replication;

SELECT 'offices' AS t_name, COUNT(*) AS cnt FROM offices
UNION ALL
SELECT 'workplaces', COUNT(*) FROM workplaces
UNION ALL
SELECT 'bookings', COUNT(*) FROM bookings
UNION ALL
SELECT 'audit_log', COUNT(*) FROM audit_log;

USE office_booking_ignore;

SELECT 'ignored_events' AS t_name, COUNT(*) AS cnt FROM ignored_events;
