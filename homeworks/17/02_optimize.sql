USE office_booking_profile;

CREATE INDEX idx_bookings_period_status_workplace
ON bookings (starts_at, status_id, workplace_id);

CREATE INDEX idx_bookings_workplace_period_status
ON bookings (workplace_id, starts_at, status_id);

CREATE INDEX idx_workplaces_active_zone_type
ON workplaces (is_active, zone_id, type_id);

ANALYZE TABLE bookings;
ANALYZE TABLE workplaces;
