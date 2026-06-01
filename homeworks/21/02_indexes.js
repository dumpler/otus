db = db.getSiblingDB('office_booking_mongo');

print('Before index');
printjson(
  db.bookings.find({
    workplace_code: 'A-501',
    starts_at: {
      $gte: ISODate('2026-06-01T00:00:00Z'),
      $lt: ISODate('2026-06-02T00:00:00Z')
    }
  }).explain('executionStats').executionStats
);

db.bookings.createIndex({ workplace_code: 1, starts_at: 1 });
db.workplaces.createIndex({ office_code: 1, type: 1, is_active: 1 });

print('After index');
printjson(
  db.bookings.find({
    workplace_code: 'A-501',
    starts_at: {
      $gte: ISODate('2026-06-01T00:00:00Z'),
      $lt: ISODate('2026-06-02T00:00:00Z')
    }
  }).explain('executionStats').executionStats
);

print('Indexes');
printjson(db.bookings.getIndexes());
printjson(db.workplaces.getIndexes());
