# Дополнительные объекты базы office_booking

## Назначение второй части

В первой части была описана базовая структура базы `office_booking`: схемы, таблицы, ключи, связи и ограничения

Во второй части к этой структуре добавляются объекты, которые отвечают за поведение базы данных:

- функции
- триггеры
- индексы
- дополнительные логические ограничения
- представление для активных бронирований

Эти объекты находятся в файле `objects.sql` и применяются после создания таблиц из `init.sql`

## Анализ запросов и отчетов

Для базы `office_booking` ожидаются такие частые запросы:

- список сотрудников по отделу
- список сотрудников по роли
- список рабочих мест в зоне
- получение SVG-планов по этажу
- получение координат рабочих мест на плане
- бронирования конкретного сотрудника
- активные бронирования по рабочему месту и периоду времени
- история статусов конкретного бронирования
- аудит изменений по таблице и периоду времени

Эти сценарии используются в демонстрационных отчетах, проверке доступности рабочих мест и административном просмотре данных

## Кардинальность полей

При выборе индексов учитывается примерная кардинальность полей:

- `office.employees.department_code` - низкая или средняя кардинальность, сотрудников много, отделов меньше
- `office.employee_roles.role_code` - низкая кардинальность, ролей мало, назначений ролей может быть много
- `office.workplaces.zone_id` - средняя кардинальность, зон меньше чем рабочих мест
- `office.floor_plans.floor_id` - средняя кардинальность, на один этаж может быть несколько версий плана
- `office.workplace_map_points.workplace_id` - высокая кардинальность, точка обычно связана с конкретным рабочим местом
- `booking.bookings.employee_id` - высокая кардинальность, у каждого сотрудника может быть много бронирований
- `booking.bookings.workplace_id` вместе с `booked_period` - высокая кардинальность и диапазонный поиск
- `booking.booking_status_history.booking_id` - высокая кардинальность, история выбирается по конкретному бронированию
- `audit.change_log.schema_name`, `table_name`, `changed_at` - составной поиск по таблице и времени

## Функции

### audit.log_row_change()

Функция используется для аудита изменений

Она вызывается триггерами после операций `INSERT`, `UPDATE` и `DELETE` на важных таблицах

Функция записывает в `audit.change_log`:

- имя схемы измененной таблицы
- имя таблицы
- тип операции
- первичный ключ строки
- старое состояние строки в `old_data`
- новое состояние строки в `new_data`
- дату изменения
- пользователя базы данных

Старые и новые значения сохраняются в формате `JSONB`, поэтому журнал аудита хранит полный снимок измененной строки

### booking.log_booking_status_change()

Функция отвечает за историю статусов бронирования

Она срабатывает:

- при создании бронирования
- при изменении поля `status_id`

Функция добавляет запись в `booking.booking_status_history` и сохраняет:

- идентификатор бронирования
- предыдущий статус
- новый статус
- сотрудника, который выполнил изменение
- дату изменения

Для нового бронирования старый статус равен `NULL`, потому что предыдущего состояния еще не было

### booking.validate_booking()

Функция проверяет бизнес-правила перед созданием или изменением бронирования

Проверки:

- сотрудник существует и активен
- рабочее место существует и активно
- если статус бронирования `created` или `confirmed`, рабочее место не должно быть закрыто на обслуживание в выбранный период

Если проверка не проходит, функция вызывает ошибку через `RAISE EXCEPTION`

Эта логика находится на уровне базы данных, поэтому она работает независимо от приложения, которое выполняет SQL-запрос

### office.set_updated_at()

Функция автоматически обновляет поле `updated_at` перед изменением строки

Она используется для таблиц, где важно видеть дату последнего изменения записи

## Триггеры updated_at

Для автоматического обновления `updated_at` созданы триггеры:

- `trg_departments_updated_at` для `office.departments`
- `trg_roles_updated_at` для `office.roles`
- `trg_offices_updated_at` для `office.offices`
- `trg_floors_updated_at` для `office.floors`
- `trg_zones_updated_at` для `office.zones`
- `trg_workplaces_updated_at` для `office.workplaces`
- `trg_floor_plans_updated_at` для `office.floor_plans`
- `trg_workplace_map_points_updated_at` для `office.workplace_map_points`
- `trg_bookings_updated_at` для `booking.bookings`

Все эти триггеры выполняются `BEFORE UPDATE`

Это значит, что перед сохранением измененной строки база сама записывает актуальное значение `now()` в поле `updated_at`

## Триггер проверки бронирования

### trg_bookings_validate

Триггер установлен на таблицу `booking.bookings`

Он выполняется `BEFORE INSERT OR UPDATE` и вызывает функцию `booking.validate_booking()`

Назначение:

- не дать создать бронирование для неактивного сотрудника
- не дать создать бронирование для неактивного рабочего места
- не дать забронировать рабочее место, которое закрыто на обслуживание в выбранный период

Дополнительно пересечения бронирований одного рабочего места контролируются ограничением `EXCLUDE USING gist`, которое добавляется ниже в разделе логических ограничений

## Триггер истории статусов

### trg_bookings_status_history

Триггер установлен на таблицу `booking.bookings`

Он выполняется `AFTER INSERT OR UPDATE OF status_id` и вызывает функцию `booking.log_booking_status_change()`

Назначение:

- фиксировать создание бронирования
- фиксировать каждую смену статуса
- сохранять, кто выполнил изменение

История хранится отдельно от основной таблицы бронирований, поэтому можно посмотреть не только текущий статус, но и путь бронирования по статусам

## Триггеры аудита

Аудит включен для таблиц:

- `booking.bookings`
- `office.workplaces`
- `office.floor_plans`
- `office.workplace_map_points`

Триггеры:

- `trg_bookings_audit`
- `trg_workplaces_audit`
- `trg_floor_plans_audit`
- `trg_workplace_map_points_audit`

Все они выполняются `AFTER INSERT OR UPDATE OR DELETE` и вызывают функцию `audit.log_row_change()`

В аудит попадают таблицы, которые важны для операционной работы системы:

- бронирования
- рабочие места
- планы этажей
- координаты рабочих мест на плане

Так можно восстановить, кто и когда менял важные данные, а также увидеть старое и новое состояние строки

## Логические ограничения

Дополнительные ограничения добавлены через `ALTER TABLE`

Они защищают базу от данных, которые формально могут пройти по типам колонок, но нарушают бизнес-логику

### chk_employees_email_format

```sql
ALTER TABLE office.employees
ADD CONSTRAINT chk_employees_email_format
CHECK (email LIKE '%_@_%._%');
```

Ограничение проверяет базовый формат email сотрудника

Поле `email` используется для идентификации сотрудника в отчетах и истории действий, поэтому в нем не должно быть произвольной строки

### chk_employees_name_not_blank

```sql
ALTER TABLE office.employees
ADD CONSTRAINT chk_employees_name_not_blank
CHECK (
    btrim(last_name) <> ''
    AND btrim(first_name) <> ''
);
```

Ограничение запрещает пустые фамилию и имя

Колонки `last_name` и `first_name` обязательны для отображения сотрудника в бронированиях, отчетах и представлении `booking.active_bookings`

### chk_offices_address_not_blank

```sql
ALTER TABLE office.offices
ADD CONSTRAINT chk_offices_address_not_blank
CHECK (btrim(address) <> '');
```

Ограничение запрещает пустой адрес офиса

Адрес нужен для описания офиса, так как отдельное поле города не используется

### chk_workplaces_code_not_blank

```sql
ALTER TABLE office.workplaces
ADD CONSTRAINT chk_workplaces_code_not_blank
CHECK (btrim(code) <> '');
```

Ограничение запрещает пустой код рабочего места

Код рабочего места используется в отчетах, на SVG-плане и при поиске рабочего места

### chk_workplace_unavailability_reason_not_blank

```sql
ALTER TABLE office.workplace_unavailability
ADD CONSTRAINT chk_workplace_unavailability_reason_not_blank
CHECK (btrim(reason) <> '');
```

Ограничение запрещает создавать период недоступности без причины

Это нужно, чтобы администратор и сотрудник понимали, почему рабочее место нельзя забронировать

### chk_floor_plans_dimensions_positive

```sql
ALTER TABLE office.floor_plans
ADD CONSTRAINT chk_floor_plans_dimensions_positive
CHECK (
    width_px > 0
    AND height_px > 0
);
```

Ограничение запрещает SVG-планы с нулевой или отрицательной шириной и высотой

План этажа используется для отображения рабочих мест, поэтому размеры должны быть корректными

### chk_floor_plans_svg_content

```sql
ALTER TABLE office.floor_plans
ADD CONSTRAINT chk_floor_plans_svg_content
CHECK (svg_content LIKE '%<svg%');
```

Ограничение проверяет, что в поле `svg_content` действительно похоже на SVG-документ

Это снижает риск сохранить вместо плана произвольный текст

### chk_workplace_map_points_coordinates

```sql
ALTER TABLE office.workplace_map_points
ADD CONSTRAINT chk_workplace_map_points_coordinates
CHECK (
    x_px >= 0
    AND y_px >= 0
    AND width_px > 0
    AND height_px > 0
);
```

Ограничение проверяет координаты и размеры точки рабочего места на плане

Координаты не должны быть отрицательными, а область рабочего места должна иметь положительные размеры

### chk_bookings_period

```sql
ALTER TABLE booking.bookings
ADD CONSTRAINT chk_bookings_period
CHECK (lower(booked_period) < upper(booked_period));
```

Ограничение запрещает бронирования, где начало периода не раньше окончания

Без этого можно получить некорректный временной интервал

### chk_bookings_cancellation_fields

```sql
ALTER TABLE booking.bookings
ADD CONSTRAINT chk_bookings_cancellation_fields
CHECK (
    (cancelled_at IS NULL AND cancellation_reason_id IS NULL)
    OR (cancelled_at IS NOT NULL AND cancellation_reason_id IS NOT NULL)
);
```

Ограничение связывает дату отмены и причину отмены

Если бронирование отменено, должна быть указана причина, а если отмены нет, причина отмены не должна быть заполнена

### ex_bookings_no_workplace_period_overlap

```sql
ALTER TABLE booking.bookings
ADD CONSTRAINT ex_bookings_no_workplace_period_overlap
EXCLUDE USING gist (
    workplace_id WITH =,
    booked_period WITH &&
) WHERE (status_id IN (1, 2));
```

Ограничение запрещает пересекающиеся активные бронирования одного рабочего места

Оно применяется только к статусам `created` и `confirmed`, потому что отмененные и завершенные бронирования не занимают рабочее место

### chk_workplace_unavailability_period

```sql
ALTER TABLE office.workplace_unavailability
ADD CONSTRAINT chk_workplace_unavailability_period
CHECK (lower(unavailable_period) < upper(unavailable_period));
```

Ограничение запрещает некорректный период недоступности рабочего места

### ex_workplace_unavailability_no_period_overlap

```sql
ALTER TABLE office.workplace_unavailability
ADD CONSTRAINT ex_workplace_unavailability_no_period_overlap
EXCLUDE USING gist (
    workplace_id WITH =,
    unavailable_period WITH &&
);
```

Ограничение запрещает пересекающиеся периоды недоступности одного рабочего места

Это упрощает проверку доступности и не дает создать две конфликтующие записи обслуживания

## Индексы

Индексы добавлены для ускорения частых соединений, фильтрации и отчетных запросов

### idx_employees_department_code

```sql
CREATE INDEX idx_employees_department_code ON office.employees(department_code);
```

Ускоряет поиск сотрудников по отделу и соединение с `office.departments`

Кардинальность поля средняя: отделов меньше, чем сотрудников, но выборка по отделу является типовым отчетным сценарием

### idx_employee_roles_role_code

```sql
CREATE INDEX idx_employee_roles_role_code ON office.employee_roles(role_code);
```

Ускоряет поиск сотрудников по роли

Кардинальность поля низкая: ролей немного, но таблица назначений может расти, поэтому индекс ускоряет выборку всех пользователей с конкретной ролью

### idx_workplaces_zone_id

```sql
CREATE INDEX idx_workplaces_zone_id ON office.workplaces(zone_id);
```

Ускоряет получение рабочих мест внутри зоны

Кардинальность поля средняя: зон меньше, чем рабочих мест, а получение рабочих мест зоны нужно для отображения карты этажа

### idx_floor_plans_floor_id

```sql
CREATE INDEX idx_floor_plans_floor_id ON office.floor_plans(floor_id);
```

Ускоряет получение SVG-планов по этажу

Кардинальность поля средняя: у этажа может быть несколько версий плана, поэтому индекс помогает быстро найти планы нужного этажа

### idx_workplace_map_points_workplace_id

```sql
CREATE INDEX idx_workplace_map_points_workplace_id ON office.workplace_map_points(workplace_id);
```

Ускоряет поиск точки на плане по рабочему месту

Кардинальность поля высокая: каждое рабочее место имеет свою точку на плане, индекс полезен при переходе от рабочего места к координатам

### idx_bookings_employee_id

```sql
CREATE INDEX idx_bookings_employee_id ON booking.bookings(employee_id);
```

Ускоряет получение бронирований конкретного сотрудника

Кардинальность поля высокая: сотрудников много, у одного сотрудника может быть несколько бронирований

### idx_bookings_workplace_period

```sql
CREATE INDEX idx_bookings_workplace_period ON booking.bookings USING gist(workplace_id, booked_period);
```

GiST-индекс нужен для работы с диапазонами времени

Он ускоряет запросы, которые проверяют пересечение периода бронирования с другим периодом через оператор `&&`

Например, такой индекс полезен при поиске бронирований рабочего места на выбранный день или интервал времени

Это композитный GiST-индекс по рабочему месту и диапазону времени

Он выбран потому, что основной поиск доступности идет не только по `workplace_id`, но и по пересечению `booked_period`

### idx_booking_history_booking_id

```sql
CREATE INDEX idx_booking_history_booking_id ON booking.booking_status_history(booking_id);
```

Ускоряет получение истории статусов по конкретному бронированию

Кардинальность поля высокая: бронирований много, а историю обычно открывают для одной конкретной записи

### idx_audit_change_log_table

```sql
CREATE INDEX idx_audit_change_log_table ON audit.change_log(schema_name, table_name, changed_at);
```

Ускоряет просмотр аудита по конкретной таблице и периоду времени

Это композитный индекс для типового фильтра аудита: схема, таблица, затем сортировка или ограничение по времени

## Представление booking.active_bookings

Представление `booking.active_bookings` собирает активные бронирования в удобный для чтения вид

В него попадают бронирования со статусами:

- `created`
- `confirmed`

Представление объединяет данные из таблиц:

- `booking.bookings`
- `office.employees`
- `office.workplaces`
- `office.zones`
- `office.floors`
- `office.offices`
- `booking.booking_statuses`

В результате можно получить:

- идентификатор бронирования
- ФИО и email сотрудника
- офис
- этаж
- зону
- код рабочего места
- начало и конец периода бронирования
- статус

Представление удобно использовать в отчетах и интерфейсе, потому что оно скрывает сложные соединения между таблицами
