import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/student_dao.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';
import 'package:olcerim/features/rubrics/domain/rubric_draft.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> classroom() async {
    final year = await db.schoolDao.activeSchoolYear();
    return db.schoolDao.saveClassroom(schoolYearId: year!.id, name: '10/Test', courseName: 'Türk Dili ve Edebiyatı');
  }

  test('öğrenci toplu yazımı duplicate hatasında tamamen rollback olur', () async {
    final classId = await classroom();
    await expectLater(
      db.studentDao.insertMultipleStudents(classId, const [StudentImportRecord(fullName: 'Ada Test', schoolNumber: '1'), StudentImportRecord(fullName: 'Bora Test', schoolNumber: '1')]),
      throwsA(anything),
    );
    expect(await db.studentDao.studentsForClassroom(classId), isEmpty);
  });

  test('classroom silinirse foreign key studentı cascade siler', () async {
    final classId = await classroom();
    await db.studentDao.saveStudent(classroomId: classId, schoolNumber: '1', fullName: 'Ada Test');
    await (db.delete(db.classrooms)..where((row) => row.id.equals(classId))).go();
    expect(await db.studentDao.studentsForClassroom(classId), isEmpty);
  });

  test('puan maksimum kriter puanını aşamaz', () async {
    final classId = await classroom();
    await db.studentDao.saveStudent(classroomId: classId, schoolNumber: '1', fullName: 'Ada Test');
    final rubricId = await db.rubricDao.saveDraft(RubricDraft(title: 'Sentetik rubrik', criteria: [CriterionDraft(title: 'İçerik', maxScore: 20)]));
    final assessmentId = await db.assessmentDao.createAssessment(classroomId: classId, rubricId: rubricId, type: AssessmentType.rubric, title: 'Sentetik değerlendirme', assessmentDate: DateTime(2026, 8, 15));
    final student = (await db.evaluationDao.watchStudentsForAssessment(assessmentId).first).single;
    final criterion = (await db.evaluationDao.criteriaForAssessment(assessmentId)).single;
    expect(() => db.evaluationDao.upsertScore(evaluationId: student.evaluation.id, criterionId: criterion.id, score: 21), throwsA(isA<ArgumentError>()));
  });
}
