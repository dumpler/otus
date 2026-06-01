db = db.getSiblingDB('office_booking_mongo');

db.offices.insertMany([
  {
    code: 'msk_main',
    name: 'Moscow Main Office',
    city: 'Moscow',
    zones: ['open_a', 'quiet_a', 'meeting_a']
  },
  {
    code: 'spb_center',
    name: 'Saint Petersburg Center',
    city: 'Saint Petersburg',
    zones: ['open_b', 'quiet_b']
  }
]);

db.workplaces.insertMany([
  {
    code: 'A-501',
    office_code: 'msk_main',
    zone_code: 'open_a',
    type: 'standard',
    seats_count: 1,
    has_monitor: true,
    is_active: true
  },
  {
    code: 'Q-501',
    office_code: 'msk_main',
    zone_code: 'quiet_a',
    type: 'focus_room',
    seats_count: 1,
    has_monitor: true,
    is_active: true
  },
  {
    code: 'M-501',
    office_code: 'msk_main',
    zone_code: 'meeting_a',
    type: 'meeting_room',
    seats_count: 8,
    has_monitor: true,
    is_active: true
  },
  {
    code: 'B-401',
    office_code: 'spb_center',
    zone_code: 'open_b',
    type: 'standard',
    seats_count: 1,
    has_monitor: false,
    is_active: true
  }
]);

db.bookings.insertMany([
  {
    workplace_code: 'A-501',
    employee_email: 'ivan.petrov@example.com',
    starts_at: ISODate('2026-06-01T09:00:00Z'),
    ends_at: ISODate('2026-06-01T18:00:00Z'),
    status_code: 'confirmed'
  },
  {
    workplace_code: 'Q-501',
    employee_email: 'maria.kuznetsova@example.com',
    starts_at: ISODate('2026-06-02T09:00:00Z'),
    ends_at: ISODate('2026-06-02T18:00:00Z'),
    status_code: 'created'
  },
  {
    workplace_code: 'M-501',
    employee_email: 'pavel.ivanov@example.com',
    starts_at: ISODate('2026-06-03T10:00:00Z'),
    ends_at: ISODate('2026-06-03T12:00:00Z'),
    status_code: 'confirmed'
  }
]);
