SELECT @@hostname AS node_name;

SHOW STATUS LIKE 'wsrep_cluster_size';
SHOW STATUS LIKE 'wsrep_cluster_status';
SHOW STATUS LIKE 'wsrep_local_state_comment';
SHOW STATUS LIKE 'wsrep_ready';

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'office_booking_cluster'
ORDER BY table_name;

SET @workplaces_sql = IF(
    EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'office_booking_cluster'
          AND table_name = 'workplaces'
    ),
    'SELECT COUNT(*) AS workplaces_count FROM office_booking_cluster.workplaces',
    'SELECT 0 AS workplaces_count'
);

PREPARE workplaces_stmt FROM @workplaces_sql;
EXECUTE workplaces_stmt;
DEALLOCATE PREPARE workplaces_stmt;
