-- Выполнять в основной базе данных после подготовки демонстрационных данных
-- docker compose exec -T office_booking_db psql -U office_booking_user -d office_booking -f /scripts/04_reports.sql

-- 1. Реплицированные сотрудники с отделами и ролями
SELECT
    e.id,
    e.last_name,
    e.first_name,
    e.middle_name,
    e.email,
    d.name AS department_name,
    e.position_name,
    e.is_active,
    COALESCE(string_agg(er.role_code, ', ' ORDER BY er.role_code), '-') AS roles
FROM office.employees e
LEFT JOIN office.departments d ON d.code = e.department_code
LEFT JOIN office.employee_roles er ON er.employee_id = e.id
GROUP BY
    e.id,
    e.last_name,
    e.first_name,
    e.middle_name,
    e.email,
    d.name,
    e.position_name,
    e.is_active
ORDER BY e.id;

-- 2. Точки рабочих мест для отображения интерактивного плана этажа
SELECT
    o.name AS office_name,
    f.number AS floor_number,
    fp.file_name,
    w.code AS workplace_code,
    wmp.x_px,
    wmp.y_px,
    wmp.width_px,
    wmp.height_px,
    wmp.label
FROM office.workplace_map_points wmp
JOIN office.floor_plans fp ON fp.id = wmp.floor_plan_id
JOIN office.floors f ON f.id = fp.floor_id
JOIN office.offices o ON o.id = f.office_id
JOIN office.workplaces w ON w.id = wmp.workplace_id
ORDER BY o.name, f.number, w.code;

-- 3. Активные бронирования
SELECT *
FROM booking.active_bookings
ORDER BY starts_at, workplace_code;

-- 4. Загрузка офиса по дням
SELECT
    o.name AS office_name,
    date(lower(b.booked_period)) AS booking_date,
    count(*) AS bookings_count,
    count(*) FILTER (
        WHERE bs.code IN ('created', 'confirmed')
    ) AS active_bookings_count
FROM booking.bookings b
JOIN booking.booking_statuses bs ON bs.id = b.status_id
JOIN office.workplaces w ON w.id = b.workplace_id
JOIN office.zones z ON z.id = w.zone_id
JOIN office.floors f ON f.id = z.floor_id
JOIN office.offices o ON o.id = f.office_id
GROUP BY o.name, date(lower(b.booked_period))
ORDER BY booking_date, office_name;

-- 5. Загрузка по зонам
SELECT
    o.name AS office_name,
    f.number AS floor_number,
    z.name AS zone_name,
    count(*) AS bookings_count
FROM booking.bookings b
JOIN office.workplaces w ON w.id = b.workplace_id
JOIN office.zones z ON z.id = w.zone_id
JOIN office.floors f ON f.id = z.floor_id
JOIN office.offices o ON o.id = f.office_id
GROUP BY o.name, f.number, z.name
ORDER BY bookings_count DESC, zone_name;

-- 6. Свободные рабочие места на выбранный временной интервал
WITH requested_period AS (
    SELECT tstzrange('2026-06-03 09:00:00+03', '2026-06-03 18:00:00+03', '[)') AS period
)
SELECT
    o.name AS office_name,
    f.number AS floor_number,
    z.name AS zone_name,
    w.code AS workplace_code,
    wt.name AS workplace_type,
    w.has_monitor,
    w.has_docking_station
FROM office.workplaces w
JOIN office.workplace_types wt ON wt.id = w.type_id
JOIN office.zones z ON z.id = w.zone_id
JOIN office.floors f ON f.id = z.floor_id
JOIN office.offices o ON o.id = f.office_id
CROSS JOIN requested_period rp
WHERE w.is_active
  AND NOT EXISTS (
      SELECT 1
      FROM booking.bookings b
      JOIN booking.booking_statuses bs ON bs.id = b.status_id
      WHERE b.workplace_id = w.id
        AND bs.code IN ('created', 'confirmed')
        AND b.booked_period && rp.period
  )
  AND NOT EXISTS (
      SELECT 1
      FROM office.workplace_unavailability wu
      WHERE wu.workplace_id = w.id
        AND wu.unavailable_period && rp.period
  )
ORDER BY office_name, floor_number, zone_name, workplace_code;

-- 7. История изменения статусов бронирований
SELECT
    bsh.booking_id,
    old_status.code AS old_status,
    new_status.code AS new_status,
    actor.email AS changed_by,
    bsh.changed_at
FROM booking.booking_status_history bsh
LEFT JOIN booking.booking_statuses old_status ON old_status.id = bsh.old_status_id
JOIN booking.booking_statuses new_status ON new_status.id = bsh.new_status_id
LEFT JOIN office.employees actor ON actor.id = bsh.changed_by_employee_id
ORDER BY bsh.id;

-- 8. Журнал аудита
SELECT
    schema_name,
    table_name,
    operation,
    row_pk,
    changed_by,
    changed_at
FROM audit.change_log
ORDER BY id;
