SELECT @@server_id AS server_id, @@gtid_mode AS gtid_mode, @@read_only AS read_only, @@super_read_only AS super_read_only;

SHOW REPLICA STATUS\G

USE office_booking_replication;

SELECT 'offices' AS t_name, COUNT(*) AS cnt FROM offices
UNION ALL
SELECT 'workplaces', COUNT(*) FROM workplaces
UNION ALL
SELECT 'bookings', COUNT(*) FROM bookings
UNION ALL
SELECT 'audit_log', COUNT(*) FROM audit_log;

SELECT SCHEMA_NAME
FROM INFORMATION_SCHEMA.SCHEMATA
WHERE SCHEMA_NAME = 'office_booking_ignore';
