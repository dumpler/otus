USE office_booking_indexes;

CREATE INDEX idx_bookings_workplace_status_start
ON bookings (workplace_id, status_id, starts_at);

CREATE INDEX idx_employees_department_active
ON employees (department_id, is_active);

CREATE FULLTEXT INDEX ft_workplaces_search
ON workplaces (name, description, properties);
