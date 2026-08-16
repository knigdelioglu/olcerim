import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/services/backup_restore_service.dart';
import 'package:olcerim/features/backup/data/backup_repository.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';
import 'package:olcerim/features/rubrics/domain/rubric_draft.dart';

void main() {
  const password = 'guvenli-round-trip-parolasi';
  late AppDatabase source;
  late AppDatabase target;
  late AppDatabase rollbackTarget;

  setUp(() {
    source = AppDatabase.forTesting(NativeDatabase.memory());
    target = AppDatabase.forTesting(NativeDatabase.memory());
    rollbackTarget = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await source.close();
    await target.close();
    await rollbackTarget.close();
  });

  test('DB A -> encrypted backup -> clean DB B tüm kullanıcı verisini birebir korur', () async {
    await _seedCompleteDataset(source);
    final expectedPayload = await source.exportBackupPayload();
    final expectedData = expectedPayload['data'] as Map<String, dynamic>;

    final crypto = BackupRestoreService();
    final sourceRepository = BackupRepository(source, crypto);
    final targetRepository = BackupRepository(target, crypto);

    final encrypted = await sourceRepository.create(password);
    final decoded = await targetRepository.decode(encrypted, password);

    expect(decoded.data, equals(expectedData));
    expect(decoded.preview.databaseSchemaVersion, source.schemaVersion);
    expect(
      decoded.preview.counts.entries.where((entry) => entry.value == 0),
      isEmpty,
      reason: 'Fixture, backup kapsamındaki her tabloyu gerçek veriyle doldurmalıdır.',
    );

    await targetRepository.restore(decoded);

    final restoredPayload = await target.exportBackupPayload();
    expect(restoredPayload['data'], equals(expectedData));
    expect(await target.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });

  test('restore ortasında FK hatası olursa mevcut DB tamamen rollback olur', () async {
    await _seedCompleteDataset(source);
    await _seedRollbackSentinel(rollbackTarget);

    final before = await rollbackTarget.exportBackupPayload();
    final beforeData = before['data'] as Map<String, dynamic>;

    final crypto = BackupRestoreService();
    final encrypted = await BackupRepository(source, crypto).create(password);
    final decoded = await BackupRepository(source, crypto).decode(encrypted, password);
    final badData = _copyBackupData(decoded.data);

    final students = badData['students']! as List<Map<String, dynamic>>;
    students.first['classroomId'] = 999999;
    final invalidBackup = DecodedBackup(preview: decoded.preview, data: badData);

    await expectLater(
      BackupRepository(rollbackTarget, crypto).restore(invalidBackup),
      throwsA(anything),
    );

    final after = await rollbackTarget.exportBackupPayload();
    expect(after['data'], equals(beforeData));
    expect(await rollbackTarget.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
}

Future<void> _seedCompleteDataset(AppDatabase db) async {
  final year = await db.schoolDao.activeSchoolYear();
  expect(year, isNotNull);

  final classroomId = await db.schoolDao.saveClassroom(
    schoolYearId: year!.id,
    name: '10/Test',
    courseName: 'Türk Dili ve Edebiyatı',
    description: 'Backup round-trip sınıfı',
  );
  await db.studentDao.saveStudent(
    classroomId: classroomId,
    schoolNumber: '101',
    fullName: 'Sentetik Öğrenci',
  );

  final rubricId = await db.rubricDao.saveDraft(
    RubricDraft(
      title: 'Sentetik Rubrik',
      description: 'Backup kapsam testi',
      criteria: [
        CriterionDraft(
          title: 'İçerik',
          description: 'İçerik doğruluğu',
          maxScore: 20,
          levels: [
            LevelDraft(label: 'Gelişiyor', description: 'Kısmi başarı', score: 10),
            LevelDraft(label: 'Tam', description: 'Beklenen başarı', score: 20),
          ],
        ),
      ],
    ),
  );

  final assessmentId = await db.assessmentDao.createAssessment(
    classroomId: classroomId,
    rubricId: rubricId,
    type: AssessmentType.rubric,
    title: 'Sentetik Değerlendirme',
    description: 'Backup round-trip değerlendirmesi',
    assessmentDate: DateTime(2026, 8, 16),
  );
  final studentRow = (await db.evaluationDao.watchStudentsForAssessment(assessmentId).first).single;
  final criterion = (await db.evaluationDao.criteriaForAssessment(assessmentId)).single;

  await db.evaluationDao.upsertScore(
    evaluationId: studentRow.evaluation.id,
    criterionId: criterion.id,
    score: 18,
    note: 'Kriter notu korunmalı.',
  );
  await db.evaluationDao.saveStudentNote(
    studentRow.evaluation.id,
    'Öğretmen notu korunmalı.',
  );
  await db.evaluationDao.addObservation(
    studentRow.evaluation.id,
    'Gözlem notu korunmalı.',
  );
  await db.assessmentDao.setStatus(assessmentId, AssessmentStatus.completed);
  await db.setSetting('themeMode', 'dark');
}

Future<void> _seedRollbackSentinel(AppDatabase db) async {
  final year = await db.schoolDao.activeSchoolYear();
  expect(year, isNotNull);
  final classroomId = await db.schoolDao.saveClassroom(
    schoolYearId: year!.id,
    name: 'Korunan Sınıf',
    courseName: 'Korunan Ders',
  );
  await db.studentDao.saveStudent(
    classroomId: classroomId,
    schoolNumber: '999',
    fullName: 'Korunan Öğrenci',
  );
  await db.setSetting('rollbackSentinel', 'korunmali');
}

Map<String, dynamic> _copyBackupData(Map<String, dynamic> source) {
  return source.map((key, value) {
    final rows = (value as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    return MapEntry<String, dynamic>(key, rows);
  });
}
