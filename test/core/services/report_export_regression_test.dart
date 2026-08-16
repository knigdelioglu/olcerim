import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/services/excel_service.dart';
import 'package:olcerim/core/services/pdf_export_service.dart';
import 'package:olcerim/core/services/tabular_export_service.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';
import 'package:olcerim/features/rubrics/domain/rubric_draft.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('CSV ve XLSX aynı Türkçe değerlendirme verisini kayıpsız taşır', () async {
    final fixture = await _seedReportFixture(db);
    final results = await db.evaluationDao.loadResults(fixture.assessmentId);
    final tabular = TabularExportService();

    final csvBytes = tabular.csvBytes(results);
    final csvRows = csv.decode(utf8.decode(csvBytes)).map(
          (row) => row.map((cell) => '$cell').toList(),
        ).toList();

    expect(csvRows, hasLength(3));
    expect(
      csvRows.first,
      [
        'No',
        'Öğrenci',
        'İçerik',
        'İçerik · Kriter notu',
        'Anlatım',
        'Anlatım · Kriter notu',
        'Öğretmen notu',
        'Gözlemler',
        'Toplam',
        'Durum',
      ],
    );
    expect(csvRows[1][0], '101');
    expect(csvRows[1][1], 'Çağrı Şahin');
    expect(csvRows[1][2], '17.0');
    expect(csvRows[1][3], 'Güçlü içerik; kanıt yerinde.');
    expect(csvRows[1][4], '8.0');
    expect(csvRows[1][6], 'Öğretmen notu: gelişiyor.');
    expect(csvRows[1][7], contains('Şiiri doğru tonladı.'));
    expect(csvRows[1][8], '25.0');
    expect(csvRows[1][9], 'Tamamlandı');

    expect(csvRows[2][0], '102');
    expect(csvRows[2][1], 'İpek Öztürk');
    expect(csvRows[2][2], '12.0');
    expect(csvRows[2][4], '');
    expect(csvRows[2][8], '12.0');
    expect(csvRows[2][9], 'Eksik');

    final xlsxBytes = tabular.xlsxBytes(results);
    final xlsxPreview = await ExcelService().parseStudentList(xlsxBytes, 'xlsx');
    expect(xlsxPreview.headers, csvRows.first);
    expect(xlsxPreview.rows, csvRows.skip(1).toList());
  });

  test('sınıf ve öğrenci PDF çıktıları Türkçe veriyle geçerli PDF üretir', () async {
    final fixture = await _seedReportFixture(db);
    final results = await db.evaluationDao.loadResults(fixture.assessmentId);
    final pdf = PdfExportService();

    final classBytes = await pdf.classAssessment(results);
    final studentBytes = await pdf.studentAssessment(results, results.students.first);

    expect(classBytes.take(4).toList(), [0x25, 0x50, 0x44, 0x46]);
    expect(studentBytes.take(4).toList(), [0x25, 0x50, 0x44, 0x46]);
    expect(classBytes.length, greaterThan(1000));
    expect(studentBytes.length, greaterThan(1000));
  });

  test('öğrencisiz değerlendirme header-only tablo ve geçerli PDF üretir', () async {
    final year = await db.schoolDao.activeSchoolYear();
    expect(year, isNotNull);

    final classroomId = await db.schoolDao.saveClassroom(
      schoolYearId: year!.id,
      name: 'Boş Sınıf',
      courseName: 'Türk Dili ve Edebiyatı',
    );
    final rubricId = await db.rubricDao.saveDraft(
      RubricDraft(
        title: 'Boş sınıf rubriği',
        criteria: [CriterionDraft(title: 'İçerik', maxScore: 20)],
      ),
    );
    final assessmentId = await db.assessmentDao.createAssessment(
      classroomId: classroomId,
      rubricId: rubricId,
      type: AssessmentType.rubric,
      title: 'Öğrencisiz değerlendirme',
      assessmentDate: DateTime(2026, 8, 16),
    );
    final results = await db.evaluationDao.loadResults(assessmentId);
    expect(results.students, isEmpty);

    final tabular = TabularExportService();
    final csvRows = csv.decode(utf8.decode(tabular.csvBytes(results)));
    expect(csvRows, hasLength(1));

    final xlsxPreview = await ExcelService().parseStudentList(tabular.xlsxBytes(results), 'xlsx');
    expect(xlsxPreview.headers, isNotEmpty);
    expect(xlsxPreview.rows, isEmpty);

    final pdfBytes = await PdfExportService().classAssessment(results);
    expect(pdfBytes.take(4).toList(), [0x25, 0x50, 0x44, 0x46]);
    expect(pdfBytes.length, greaterThan(500));
  });
}

Future<({int assessmentId})> _seedReportFixture(AppDatabase db) async {
  final year = await db.schoolDao.activeSchoolYear();
  expect(year, isNotNull);

  final classroomId = await db.schoolDao.saveClassroom(
    schoolYearId: year!.id,
    name: '10/Ş',
    courseName: 'Türk Dili ve Edebiyatı',
    description: 'Türkçe export regresyon sınıfı',
  );
  await db.studentDao.saveStudent(
    classroomId: classroomId,
    schoolNumber: '101',
    fullName: 'Çağrı Şahin',
  );
  await db.studentDao.saveStudent(
    classroomId: classroomId,
    schoolNumber: '102',
    fullName: 'İpek Öztürk',
  );

  final rubricId = await db.rubricDao.saveDraft(
    RubricDraft(
      title: 'Şiir Sunumu',
      description: 'Türkçe karakter ve not regresyonu',
      criteria: [
        CriterionDraft(title: 'İçerik', maxScore: 20),
        CriterionDraft(title: 'Anlatım', maxScore: 10),
      ],
    ),
  );
  final assessmentId = await db.assessmentDao.createAssessment(
    classroomId: classroomId,
    rubricId: rubricId,
    type: AssessmentType.rubric,
    title: 'Şiir Değerlendirmesi',
    description: 'Öğrenci, kriter ve gözlem notlarını içerir.',
    assessmentDate: DateTime(2026, 8, 16),
  );

  final students = await db.evaluationDao.watchStudentsForAssessment(assessmentId).first;
  final criteria = await db.evaluationDao.criteriaForAssessment(assessmentId);

  await db.evaluationDao.upsertScore(
    evaluationId: students[0].evaluation.id,
    criterionId: criteria[0].id,
    score: 17,
    note: 'Güçlü içerik; kanıt yerinde.',
  );
  await db.evaluationDao.upsertScore(
    evaluationId: students[0].evaluation.id,
    criterionId: criteria[1].id,
    score: 8,
  );
  await db.evaluationDao.saveStudentNote(
    students[0].evaluation.id,
    'Öğretmen notu: gelişiyor.',
  );
  await db.evaluationDao.addObservation(
    students[0].evaluation.id,
    'Şiiri doğru tonladı.',
  );

  await db.evaluationDao.upsertScore(
    evaluationId: students[1].evaluation.id,
    criterionId: criteria[0].id,
    score: 12,
  );

  return (assessmentId: assessmentId);
}
