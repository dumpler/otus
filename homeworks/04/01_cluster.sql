CREATE ROLE office_booking_owner
WITH
    LOGIN
    PASSWORD 'office_booking_owner_password';

CREATE ROLE office_booking_app
WITH
    LOGIN
    PASSWORD 'office_booking_app_password';

CREATE ROLE office_booking_readonly
WITH
    LOGIN
    PASSWORD 'office_booking_readonly_password';

CREATE TABLESPACE office_core_ts
OWNER office_booking_owner
LOCATION '/var/lib/postgresql/tablespaces/office_core';

CREATE TABLESPACE office_booking_ts
OWNER office_booking_owner
LOCATION '/var/lib/postgresql/tablespaces/office_booking';

CREATE TABLESPACE office_audit_ts
OWNER office_booking_owner
LOCATION '/var/lib/postgresql/tablespaces/office_audit';

CREATE DATABASE office_booking
OWNER office_booking_owner
ENCODING 'UTF8'
TABLESPACE office_core_ts;
