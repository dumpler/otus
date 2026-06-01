USE office_booking_cluster;

INSERT INTO workplaces (office_id, code, name, is_active)
VALUES (1, 'A-777', 'Desk A-777 after node failure', 1);

SELECT COUNT(*) AS workplaces_count
FROM workplaces;
