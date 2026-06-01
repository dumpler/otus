USE office_booking_profile;

SET @@explain_format = TRADITIONAL;

SELECT @@explain_format;

EXPLAIN
SELECT *
FROM v_zone_booking_profile;

EXPLAIN FORMAT=JSON
SELECT *
FROM v_zone_booking_profile;

SET @@explain_format = TREE;

SELECT @@explain_format;

EXPLAIN
SELECT *
FROM v_zone_booking_profile;

EXPLAIN ANALYZE
SELECT *
FROM v_zone_booking_profile;
