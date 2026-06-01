SET GLOBAL super_read_only = OFF;
SET GLOBAL read_only = OFF;

STOP REPLICA;

CHANGE REPLICATION SOURCE TO
    SOURCE_HOST = 'mysql-source',
    SOURCE_USER = 'repl',
    SOURCE_PASSWORD = 'repl_pass',
    SOURCE_AUTO_POSITION = 1,
    GET_SOURCE_PUBLIC_KEY = 1;

START REPLICA;

SET GLOBAL read_only = ON;
SET GLOBAL super_read_only = ON;
