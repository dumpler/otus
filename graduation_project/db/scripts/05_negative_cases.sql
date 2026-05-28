-- Выполнять в основной базе данных после настройки репликации
-- docker compose exec -T office_booking_db psql -U office_booking_user -d office_booking -f /scripts/05_negative_cases.sql

-- 1. Проверка внешнего ключа: сотрудник не может ссылаться на несуществующий отдел
DO $$
BEGIN
    INSERT INTO office.employees (
        id,
        email,
        last_name,
        first_name,
        middle_name,
        department_code,
        position_name,
        source_updated_at
    )
    VALUES (
        999,
        'bad.department@example.com',
        'User',
        'Bad',
        'Department',
        'missing_department',
        'Test user',
        now()
    );
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Ожидаемая ошибка: сотрудник с несуществующим отделом отклонен';
END;
$$;

-- 2. Неактивный сотрудник не может создать бронирование
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
        tstzrange('2026-06-04 09:00:00+03', '2026-06-04 18:00:00+03', '[)'),
        'Бронирование должно быть отклонено: сотрудник неактивен',
        e.id
    FROM office.employees e
    CROSS JOIN office.workplaces w
    CROSS JOIN booking.booking_statuses bs
    WHERE e.id = 3
      AND w.code = 'A-501'
      AND bs.code = 'confirmed';
EXCEPTION
    WHEN raise_exception THEN
        RAISE NOTICE 'Ожидаемая ошибка: бронирование неактивного сотрудника отклонено';
END;
$$;

-- 3. Период бронирования должен начинаться раньше, чем заканчиваться
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
        tstzrange('2026-06-05 18:00:00+03', '2026-06-05 09:00:00+03', '[)'),
        'Бронирование должно быть отклонено: некорректный период',
        e.id
    FROM office.employees e
    CROSS JOIN office.workplaces w
    CROSS JOIN booking.booking_statuses bs
    WHERE e.id = 1
      AND w.code = 'A-501'
      AND bs.code = 'confirmed';
EXCEPTION
    WHEN data_exception OR check_violation THEN
        RAISE NOTICE 'Ожидаемая ошибка: некорректный период бронирования отклонен';
END;
$$;

-- 4. SVG-план этажа должен содержать тег SVG
DO $$
BEGIN
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
        99,
        'invalid-plan.svg',
        '<html>not svg</html>',
        1000,
        650
    FROM office.floors f
    LIMIT 1;
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'Ожидаемая ошибка: некорректный SVG-план этажа отклонен';
END;
$$;

-- 5. Координаты и размеры точки рабочего места должны быть корректными
DO $$
BEGIN
    INSERT INTO office.workplace_map_points (
        floor_plan_id,
        workplace_id,
        x_px,
        y_px,
        width_px,
        height_px,
        label
    )
    SELECT
        fp.id,
        w.id,
        -10,
        100,
        56,
        42,
        'Invalid point'
    FROM office.floor_plans fp
    CROSS JOIN office.workplaces w
    WHERE w.code = 'A-501'
    LIMIT 1;
EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'Ожидаемая ошибка: некорректные координаты точки рабочего места отклонены';
END;
$$;
