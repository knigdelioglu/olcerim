import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/services/tabular_export_service.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';
import 'package:olcerim/features/evaluations/domain/quick_scale.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> createClassroom() async {
    final year = await db.schoolDao.activeSchoolYear();
    return db.schoolDao.saveClassroom(
      schoolYearId: year!.id,
      name: '10/A',
      courseName: 'Türk Dili ve Edebiyatı',
    );
  }

  test('quick scale creates an assessment-only scale with one-tap levels', () async {
    final classroomId = await createClassroom();
    await db.studentDao.saveStudent(
      classroomId: classroomId,
      schoolNumber: '101',
      fullName: 'Ada Öğrenci',
    );

    final assessmentId = await db.assessmentDao.createQuickScaleAssessment(
      classroomId: classroomId,
      preset: QuickScalePreset.descriptiveFour,
      title: 'Sözlü anlatım hızlı değerlendirme',
      description: 'Ders içi kısa gözlem',
      assessmentDate: DateTime(2026, 8, 16),
    );

    final detail = await db.assessmentDao.detail(assessmentId);
    expect(detail, isNotNull);
    expect(detail!.assessment.type, AssessmentType.quickScale.storageValue);
    expect(detail.rubric.isTemplate, isFalse);
    expect(await db.rubricDao.watchAllRubrics().first, isEmpty);

    final criteria = await db.evaluationDao.criteriaForAssessment(assessmentId);
    expect(criteria, hasLength(1));
    expect(criteria.single.title, 'Genel değerlendirme');
    final levels = await db.evaluationDao.levelsForCriterion(criteria.single.id);
    expect(levels.map((level) => level.label), ['Yetersiz', 'Geliştirilmeli', 'İyi', 'Çok iyi']);

    final student = (await db.evaluationDao.watchStudentsForAssessment(assessmentId).first).single;
    await db.evaluationDao.upsertScore(
      evaluationId: student.evaluation.id,
      criterionId: criteria.single.id,
      score: 3,
    );
    final updated = (await db.evaluationDao.watchStudentsForAssessment(assessmentId).first).single;
    expect(updated.evaluation.status, EvaluationStatus.completed.storageValue);
  });

  test('criterion notes and observations survive results and tabular export', () async {
    final classroomId = await createClassroom();
    await db.studentDao.saveStudent(
      classroomId: classroomId,
      schoolNumber: '102',
      fullName: 'Bora Öğrenci',
    );
    final assessmentId = await db.assessmentDao.createQuickScaleAssessment(
      classroomId: classroomId,
      preset: QuickScalePreset.numericFive,
      title: 'Okuma performansı',
      assessmentDate: DateTime(2026, 8, 16),
    );
    final evaluation = (await db.evaluationDao.watchStudentsForAssessment(assessmentId).first).single.evaluation;
    final criterion = (await db.evaluationDao.criteriaForAssessment(assessmentId)).single;

    await db.evaluationDao.upsertScore(
      evaluationId: evaluation.id,
      criterionId: criterion.id,
      score: 4,
    );
    await db.evaluationDao.saveCriterionNote(
      evaluationId: evaluation.id,
      criterionId: criterion.id,
      note: 'Vurgu ve tonlama güçlü.',
    );
    await db.evaluationDao.saveStudentNote(evaluation.id, 'Genel performans iyi.');
    await db.evaluationDao.addObservation(evaluation.id, 'Metne hazırlıklı geldi.');

    final results = await db.evaluationDao.loadResults(assessmentId);
    final student = results.students.single;
    expect(student.entries.single.note, 'Vurgu ve tonlama güçlü.');
    expect(student.note, 'Genel performans iyi.');
    expect(student.observations.single.content, 'Metne hazırlıklı geldi.');

    final csvText = utf8.decode(TabularExportService().csvBytes(results));
    expect(csvText, contains('Kriter notu'));
    expect(csvText, contains('Vurgu ve tonlama güçlü.'));
    expect(csvText, contains('Metne hazırlıklı geldi.'));
    expect(TabularExportService().xlsxBytes(results), isNotEmpty);
  });
}
