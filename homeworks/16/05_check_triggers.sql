USE office_booking_routines;

INSERT INTO bookings (
    employee_id,
    workplace_id,
    status_id,
    starts_at,
    ends_at
)
VALUES (
    4,
    1,
    1,
    '2026-06-06 09:00:00.000000',
    '2026-06-06 18:00:00.000000'
);

SELECT
    booking_id,
    action_type,
    details
FROM booking_audit
ORDER BY id DESC
LIMIT 1;
