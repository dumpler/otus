INSERT INTO office.workplace_types (code, name)
VALUES
    ('standard', 'Standard workplace'),
    ('standing_desk', 'Standing desk'),
    ('focus_room', 'Focus room');

INSERT INTO booking.booking_statuses (code, name, is_final)
VALUES
    ('created', 'Created', FALSE),
    ('confirmed', 'Confirmed', FALSE),
    ('cancelled', 'Cancelled', TRUE),
    ('completed', 'Completed', TRUE);

INSERT INTO booking.cancellation_reasons (code, name)
VALUES
    ('employee_cancelled', 'Cancelled by employee'),
    ('admin_cancelled', 'Cancelled by administrator'),
    ('workplace_unavailable', 'Workplace became unavailable');

INSERT INTO office.offices (code, name, address)
VALUES ('msk_main', 'Moscow Main Office', 'Moscow, Tverskaya street, 1');

INSERT INTO office.floors (office_id, number, name)
SELECT id, 5, 'Fifth floor'
FROM office.offices
WHERE code = 'msk_main';

INSERT INTO office.zones (floor_id, code, name, description, is_quiet_zone)
SELECT id, 'a', 'Open Space A', 'Main open space zone', FALSE
FROM office.floors
WHERE number = 5;

INSERT INTO office.zones (floor_id, code, name, description, is_quiet_zone)
SELECT id, 'q', 'Quiet Zone', 'Zone for focused work', TRUE
FROM office.floors
WHERE number = 5;

INSERT INTO office.workplaces (zone_id, type_id, code, name, has_monitor, has_docking_station)
SELECT z.id, wt.id, 'A-501', 'Desk A-501', TRUE, TRUE
FROM office.zones z
JOIN office.workplace_types wt ON wt.code = 'standard'
WHERE z.code = 'a';

INSERT INTO office.workplaces (zone_id, type_id, code, name, has_monitor, has_docking_station)
SELECT z.id, wt.id, 'A-502', 'Desk A-502', TRUE, FALSE
FROM office.zones z
JOIN office.workplace_types wt ON wt.code = 'standing_desk'
WHERE z.code = 'a';

INSERT INTO office.workplaces (zone_id, type_id, code, name, has_monitor, has_docking_station)
SELECT z.id, wt.id, 'Q-501', 'Focus room Q-501', TRUE, TRUE
FROM office.zones z
JOIN office.workplace_types wt ON wt.code = 'focus_room'
WHERE z.code = 'q';

INSERT INTO office.floor_plans (
    floor_id,
    version,
    file_name,
    svg_content,
    width_px,
    height_px
)
SELECT
    f.id,
    1,
    'msk-main-floor-5.svg',
    $svg$<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="650" viewBox="0 0 1000 650"><rect x="20" y="20" width="960" height="610" fill="#f8fafc" stroke="#334155" stroke-width="4"/><rect x="80" y="90" width="560" height="420" fill="#dbeafe" stroke="#1d4ed8" stroke-width="2"/><text x="100" y="125" font-family="Arial" font-size="24">Open Space A</text><rect x="700" y="90" width="220" height="420" fill="#dcfce7" stroke="#15803d" stroke-width="2"/><text x="720" y="125" font-family="Arial" font-size="24">Quiet Zone</text></svg>$svg$,
    1000,
    650
FROM office.floors f
JOIN office.offices o ON o.id = f.office_id
WHERE o.code = 'msk_main'
  AND f.number = 5;

INSERT INTO office.workplace_map_points (
    floor_plan_id,
    workplace_id,
    x_px,
    y_px,
    width_px,
    height_px,
    label
)
SELECT fp.id, w.id, point_data.x_px, point_data.y_px, 56, 42, w.code
FROM office.floor_plans fp
JOIN office.floors f ON f.id = fp.floor_id
JOIN office.zones z ON z.floor_id = f.id
JOIN office.workplaces w ON w.zone_id = z.id
JOIN (
    VALUES
        ('A-501', 180::NUMERIC, 220::NUMERIC),
        ('A-502', 300::NUMERIC, 220::NUMERIC),
        ('Q-501', 780::NUMERIC, 260::NUMERIC)
) AS point_data(workplace_code, x_px, y_px) ON point_data.workplace_code = w.code
WHERE fp.file_name = 'msk-main-floor-5.svg';
