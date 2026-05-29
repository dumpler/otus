SELECT
    code,
    name,
    JSON_UNQUOTE(JSON_EXTRACT(attributes, '$.equipment.monitors')) AS monitors_count,
    JSON_UNQUOTE(JSON_EXTRACT(attributes, '$.equipment.keyboard')) AS keyboard_layout
FROM workplaces
ORDER BY code;

SELECT
    code,
    name
FROM workplaces
WHERE JSON_CONTAINS(attributes, JSON_OBJECT('dock', TRUE), '$.equipment')
ORDER BY code;

SELECT
    b.id,
    e.email,
    JSON_UNQUOTE(JSON_EXTRACT(b.client_context, '$.source')) AS booking_source,
    JSON_UNQUOTE(JSON_EXTRACT(b.client_context, '$.filters.quiet')) AS quiet_filter
FROM bookings b
JOIN employees e ON e.id = b.employee_id
WHERE JSON_EXTRACT(b.client_context, '$.filters.monitor') = TRUE
ORDER BY b.id;
