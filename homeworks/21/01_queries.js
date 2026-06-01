db = db.getSiblingDB('office_booking_mongo');

print('Active workplaces with monitor');
printjson(
  db.workplaces.find(
    { is_active: true, has_monitor: true },
    { _id: 0, code: 1, office_code: 1, zone_code: 1, type: 1 }
  ).toArray()
);

print('Bookings by period');
printjson(
  db.bookings.find(
    {
      starts_at: {
        $gte: ISODate('2026-06-01T00:00:00Z'),
        $lt: ISODate('2026-06-04T00:00:00Z')
      }
    },
    { _id: 0, workplace_code: 1, employee_email: 1, status_code: 1 }
  ).toArray()
);

print('Bookings count by status');
printjson(
  db.bookings.aggregate([
    {
      $group: {
        _id: '$status_code',
        bookings_count: { $sum: 1 }
      }
    },
    { $sort: { _id: 1 } }
  ]).toArray()
);

print('Update one workplace');
printjson(
  db.workplaces.updateOne(
    { code: 'B-401' },
    { $set: { has_monitor: true }, $currentDate: { updated_at: true } }
  )
);

print('Updated workplace');
printjson(
  db.workplaces.findOne(
    { code: 'B-401' },
    { _id: 0, code: 1, has_monitor: 1, updated_at: 1 }
  )
);
