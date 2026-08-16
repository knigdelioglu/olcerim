import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('aktif eğitim yılı arşivlenemez', () async {
    final active = await db.schoolDao.activeSchoolYear();
    expect(active, isNotNull);

    await expectLater(
      db.schoolDao.setSchoolYearArchived(active!.id, true),
      throwsA(isA<StateError>()),
    );

    final after = await db.schoolDao.activeSchoolYear();
    expect(after?.id, active.id);
    expect(after?.archived, isFalse);
  });

  test('eğitim yılı arşivlenip geri yüklenebilir', () async {
    final id = await db.schoolDao.createSchoolYear(
      label: '2030–2031',
      startsAt: DateTime(2030, 9, 1),
      endsAt: DateTime(2031, 8, 31),
    );

    await db.schoolDao.setSchoolYearArchived(id, true);

    final archived = await db.schoolDao.watchArchivedSchoolYears().first;
    expect(archived.map((year) => year.id), contains(id));

    final visibleAfterArchive = await db.schoolDao.watchSchoolYears().first;
    expect(visibleAfterArchive.map((year) => year.id), isNot(contains(id)));

    await db.schoolDao.setSchoolYearArchived(id, false);

    final archivedAfterRestore = await db.schoolDao.watchArchivedSchoolYears().first;
    expect(archivedAfterRestore.map((year) => year.id), isNot(contains(id)));

    final visibleAfterRestore = await db.schoolDao.watchSchoolYears().first;
    expect(visibleAfterRestore.map((year) => year.id), contains(id));
  });

  test('eğitim yılı düzenleme etiket ve tarihleri kalıcı günceller', () async {
    final id = await db.schoolDao.createSchoolYear(
      label: '2032–2033',
      startsAt: DateTime(2032, 9, 1),
      endsAt: DateTime(2033, 8, 31),
    );

    await db.schoolDao.updateSchoolYear(
      id: id,
      label: ' 2032 / 2033 ',
      startsAt: DateTime(2032, 8, 20),
      endsAt: DateTime(2033, 7, 15),
    );

    final years = await db.schoolDao.watchSchoolYears(includeArchived: true).first;
    final updated = years.singleWhere((year) => year.id == id);

    expect(updated.label, '2032 / 2033');
    expect(updated.startsAt, DateTime(2032, 8, 20));
    expect(updated.endsAt, DateTime(2033, 7, 15));
  });

  test('arşivlenmiş eğitim yılı düzenlenemez', () async {
    final id = await db.schoolDao.createSchoolYear(
      label: '2034–2035',
      startsAt: DateTime(2034, 9, 1),
      endsAt: DateTime(2035, 8, 31),
    );
    await db.schoolDao.setSchoolYearArchived(id, true);

    await expectLater(
      db.schoolDao.updateSchoolYear(
        id: id,
        label: 'Yeni etiket',
        startsAt: DateTime(2034, 9, 1),
        endsAt: DateTime(2035, 8, 31),
      ),
      throwsA(isA<StateError>()),
    );
  });
}
