-- Выполнять в основной базе данных после настройки репликации
-- docker compose exec -T office_booking_db psql -U office_booking_user -d office_booking -f /scripts/03_booking_demo.sql

-- Очищаем демонстрационные операционные данные
-- Справочники, пришедшие через репликацию, не трогаем
TRUNCATE TABLE
    booking.bookings,
    office.workplace_unavailability,
    audit.change_log
RESTART IDENTITY CASCADE;

-- Показываем сотрудников, отделы и роли
-- Эти данные пришли из внешнего каталога directory_db через логическую репликацию
SELECT
    e.id,
    e.external_id,
    e.email,
    e.full_name,
    e.department_code,
    d.name AS department_name,
    e.position_name,
    e.is_active,
    string_agg(er.role_code, ', ' ORDER BY er.role_code) AS roles
FROM office.employees e
LEFT JOIN office.departments d ON d.code = e.department_code
LEFT JOIN office.employee_roles er ON er.employee_id = e.id
GROUP BY
    e.id,
    e.external_id,
    e.email,
    e.full_name,
    e.department_code,
    d.name,
    e.position_name,
    e.is_active
ORDER BY e.id;

-- Показываем SVG-планы этажей
-- Здесь видно, что у этажа есть сохраненный SVG-файл и количество нанесенных рабочих мест
SELECT
    o.name AS office_name,
    f.number AS floor_number,
    fp.file_name,
    fp.version,
    fp.width_px,
    fp.height_px,
    count(wmp.id) AS mapped_workplaces_count
FROM office.floor_plans fp
JOIN office.floors f ON f.id = fp.floor_id
JOIN office.offices o ON o.id = f.office_id
LEFT JOIN office.workplace_map_points wmp ON wmp.floor_plan_id = fp.id
GROUP BY o.name, f.number, fp.file_name, fp.version, fp.width_px, fp.height_px
ORDER BY o.name, f.number, fp.version;

-- Показываем координаты рабочих мест на SVG-плане
-- Эти данные можно использовать в интерфейсе для клика по рабочему месту на карте
SELECT
    fp.file_name,
    w.code AS workplace_code,
    wmp.x_px,
    wmp.y_px,
    wmp.width_px,
    wmp.height_px,
    wmp.label
FROM office.workplace_map_points wmp
JOIN office.floor_plans fp ON fp.id = wmp.floor_plan_id
JOIN office.workplaces w ON w.id = wmp.workplace_id
ORDER BY fp.file_name, w.code;

-- Создаем первое успешное бронирование рабочего места A-501
INSERT INTO booking.bookings (
    employee_id,
    workplace_id,
    status_id,
    booked_period,
    comment,
    created_by_employee_id
)
SELECT
    e.id,
    w.id,
    bs.id,
    tstzrange('2026-06-01 09:00:00+03', '2026-06-01 18:00:00+03', '[)'),
    'Regular office day',
    e.id
FROM office.employees e
CROSS JOIN office.workplaces w
CROSS JOIN booking.booking_statuses bs
WHERE e.external_id = 'ad-1001'
  AND w.code = 'A-501'
  AND bs.code = 'confirmed'
ON CONFLICT DO NOTHING;

-- Пытаемся создать пересекающееся бронирование на то же рабочее место
-- Ожидаем отказ из-за EXCLUDE USING gist
DO $$
BEGIN
    INSERT INTO booking.bookings (
        employee_id,
        workplace_id,
        status_id,
        booked_period,
        comment,
        created_by_employee_id
    )
    SELECT
        e.id,
        w.id,
        bs.id,
        tstzrange('2026-06-01 10:00:00+03', '2026-06-01 12:00:00+03', '[)'),
        'Бронирование должно быть отклонено: рабочее место уже занято',
        e.id
    FROM office.employees e
    CROSS JOIN office.workplaces w
    CROSS JOIN booking.booking_statuses bs
    WHERE e.external_id = 'ad-1002'
      AND w.code = 'A-501'
      AND bs.code = 'confirmed';
EXCEPTION
    WHEN exclusion_violation THEN
        RAISE NOTICE 'Ожидаемая ошибка: пересекающееся бронирование отклонено';
END;
$$;

-- Закрываем рабочее место A-502 на обслуживание
INSERT INTO office.workplace_unavailability (
    workplace_id,
    unavailable_period,
    reason
)
SELECT
    w.id,
    tstzrange('2026-06-02 09:00:00+03', '2026-06-02 18:00:00+03', '[)'),
    'Monitor replacement'
FROM office.workplaces w
WHERE w.code = 'A-502'
ON CONFLICT DO NOTHING;

-- Пытаемся забронировать рабочее место, закрытое на обслуживание
-- Ожидаем отказ от триггера booking.validate_booking()
DO $$
BEGIN
    INSERT INTO booking.bookings (
        employee_id,
        workplace_id,
        status_id,
        booked_period,
        comment,
        created_by_employee_id
    )
    SELECT
        e.id,
        w.id,
        bs.id,
        tstzrange('2026-06-02 10:00:00+03', '2026-06-02 16:00:00+03', '[)'),
        'Бронирование должно быть отклонено: рабочее место недоступно',
        e.id
    FROM office.employees e
    CROSS JOIN office.workplaces w
    CROSS JOIN booking.booking_statuses bs
    WHERE e.external_id = 'ad-1002'
      AND w.code = 'A-502'
      AND bs.code = 'created';
EXCEPTION
    WHEN raise_exception THEN
        RAISE NOTICE 'Ожидаемая ошибка: бронирование недоступного рабочего места отклонено';
END;
$$;

-- Создаем второе успешное бронирование
-- Оно остается активным и попадет в отчет active_bookings
INSERT INTO booking.bookings (
    employee_id,
    workplace_id,
    status_id,
    booked_period,
    comment,
    created_by_employee_id
)
SELECT
    e.id,
    w.id,
    bs.id,
    tstzrange('2026-06-03 09:00:00+03', '2026-06-03 18:00:00+03', '[)'),
    'Successful active booking for report output',
    e.id
FROM office.employees e
CROSS JOIN office.workplaces w
CROSS JOIN booking.booking_statuses bs
WHERE e.external_id = 'ad-1005'
  AND w.code = 'Q-501'
  AND bs.code = 'confirmed';

-- Отменяем первое бронирование
-- Это должно создать запись в истории статусов и аудите
UPDATE booking.bookings b
SET
    status_id = bs_cancelled.id,
    cancellation_reason_id = cr.id,
    cancelled_by_employee_id = b.employee_id,
    cancelled_at = now()
FROM booking.booking_statuses bs_cancelled
CROSS JOIN booking.cancellation_reasons cr
WHERE b.id = (
    SELECT id
    FROM booking.bookings
    ORDER BY id
    LIMIT 1
)
  AND bs_cancelled.code = 'cancelled'
  AND cr.code = 'employee_cancelled';

-- Показываем активные бронирования через представление booking.active_bookings
SELECT *
FROM booking.active_bookings
ORDER BY starts_at;

-- Показываем загрузку офиса по дням
SELECT
    o.name AS office_name,
    date(lower(b.booked_period)) AS booking_date,
    count(*) AS bookings_count
FROM booking.bookings b
JOIN office.workplaces w ON w.id = b.workplace_id
JOIN office.zones z ON z.id = w.zone_id
JOIN office.floors f ON f.id = z.floor_id
JOIN office.offices o ON o.id = f.office_id
GROUP BY o.name, date(lower(b.booked_period))
ORDER BY booking_date, office_name;

-- Показываем историю изменения статусов бронирований
SELECT
    bsh.booking_id,
    old_status.code AS old_status,
    new_status.code AS new_status,
    bsh.changed_at
FROM booking.booking_status_history bsh
LEFT JOIN booking.booking_statuses old_status ON old_status.id = bsh.old_status_id
JOIN booking.booking_statuses new_status ON new_status.id = bsh.new_status_id
ORDER BY bsh.id;

-- Показываем журнал аудита по операциям, выполненным в сценарии
SELECT
    schema_name,
    table_name,
    operation,
    row_pk,
    changed_at
FROM audit.change_log
ORDER BY id;

