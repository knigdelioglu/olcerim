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
    return db.schoolDao.saveClassroom(
      schoolYearId: year!.id,
      name: '10/Test',
      courseName: 'Türk Dili ve Edebiyatı',
    );
  }

  Future<({int assessmentId, int evaluationId, int criterionId})> assessmentFixture() async {
    final classId = await classroom();
    await db.studentDao.saveStudent(
      classroomId: classId,
      schoolNumber: '1',
      fullName: 'Ada Test',
    );
    final rubricId = await db.rubricDao.saveDraft(
      RubricDraft(
        title: 'Sentetik rubrik',
        criteria: [CriterionDraft(title: 'İçerik', maxScore: 20)],
      ),
    );
    final assessmentId = await db.assessmentDao.createAssessment(
      classroomId: classId,
      rubricId: rubricId,
      type: AssessmentType.rubric,
      title: 'Sentetik değerlendirme',
      assessmentDate: DateTime(2026, 8, 15),
    );
    final student = (await db.evaluationDao.watchStudentsForAssessment(assessmentId).first).single;
    final criterion = (await db.evaluationDao.criteriaForAssessment(assessmentId)).single;
    return (
      assessmentId: assessmentId,
      evaluationId: student.evaluation.id,
      criterionId: criterion.id,
    );
  }

  test('öğrenci toplu yazımı duplicate hatasında tamamen rollback olur', () async {
    final classId = await classroom();
    await expectLater(
      db.studentDao.insertMultipleStudents(
        classId,
        const [
          StudentImportRecord(fullName: 'Ada Test', schoolNumber: '1'),
          StudentImportRecord(fullName: 'Bora Test', schoolNumber: '1'),
        ],
      ),
      throwsA(anything),
    );
    expect(await db.studentDao.studentsForClassroom(classId), isEmpty);
  });

  test('classroom silinirse foreign key studentı cascade siler', () async {
    final classId = await classroom();
    await db.studentDao.saveStudent(
      classroomId: classId,
      schoolNumber: '1',
      fullName: 'Ada Test',
    );
    await (db.delete(db.classrooms)..where((row) => row.id.equals(classId))).go();
    expect(await db.studentDao.studentsForClassroom(classId), isEmpty);
  });

  test('puan maksimum kriter puanını aşamaz', () async {
    final fixture = await assessmentFixture();
    await expectLater(
      db.evaluationDao.upsertScore(
        evaluationId: fixture.evaluationId,
        criterionId: fixture.criterionId,
        score: 21,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('sınıf ve öğrenci mevcut id üzerinden düzenlenebilir', () async {
    final classId = await classroom();
    final year = await db.schoolDao.activeSchoolYear();
    await db.schoolDao.saveClassroom(
      id: classId,
      schoolYearId: year!.id,
      name: '10/Güncel',
      courseName: 'Edebiyat',
      description: 'Güncellendi',
    );
    final detail = await db.schoolDao.classroomDetail(classId);
    expect(detail!.classroom.name, '10/Güncel');
    expect(detail.course.name, 'Edebiyat');

    final studentId = await db.studentDao.saveStudent(
      classroomId: classId,
      schoolNumber: '10',
      fullName: 'İlk Ad',
    );
    await db.studentDao.saveStudent(
      id: studentId,
      classroomId: classId,
      schoolNumber: '11',
      fullName: 'Güncel Ad',
    );
    final students = await db.studentDao.studentsForClassroom(classId);
    expect(students.single.fullName, 'Güncel Ad');
    expect(students.single.schoolNumber, '11');
  });

  test('yeni eğitim yılı oluşturulup aktif dönem yapılabilir', () async {
    final newId = await db.schoolDao.createSchoolYear(
      label: '2027–2028',
      startsAt: DateTime(2027, 9),
      endsAt: DateTime(2028, 8, 31),
      makeActive: true,
    );
    final active = await db.schoolDao.activeSchoolYear();
    expect(active!.id, newId);
    expect(active.label, '2027–2028');
    final all = await db.schoolDao.watchSchoolYears().first;
    expect(all.where((item) => item.isActive), hasLength(1));
  });

  test('assessment status filtresi ve arşiv sorgusu ayrıdır', () async {
    final fixture = await assessmentFixture();
    expect(
      (await db.assessmentDao.watchAssessments(status: AssessmentStatus.draft.storageValue).first)
          .map((item) => item.assessment.id),
      contains(fixture.assessmentId),
    );

    await db.assessmentDao.setStatus(fixture.assessmentId, AssessmentStatus.active);
    expect(
      (await db.assessmentDao.watchAssessments(status: AssessmentStatus.active.storageValue).first)
          .map((item) => item.assessment.id),
      contains(fixture.assessmentId),
    );

    await db.assessmentDao.setArchived(fixture.assessmentId, true);
    expect(
      (await db.assessmentDao.watchAssessments().first)
          .where((item) => item.assessment.id == fixture.assessmentId),
      isEmpty,
    );
    expect(
      (await db.assessmentDao.watchAssessments(archived: true).first)
          .map((item) => item.assessment.id),
      contains(fixture.assessmentId),
    );
  });

  test('kriter notu sonraki puan değişiminde korunur', () async {
    final fixture = await assessmentFixture();
    await db.evaluationDao.upsertScore(
      evaluationId: fixture.evaluationId,
      criterionId: fixture.criterionId,
      score: 10,
    );
    await db.evaluationDao.saveCriterionNote(
      evaluationId: fixture.evaluationId,
      criterionId: fixture.criterionId,
      note: 'Akıcılık gelişiyor.',
    );
    await db.evaluationDao.upsertScore(
      evaluationId: fixture.evaluationId,
      criterionId: fixture.criterionId,
      score: 15,
    );
    final entry = (await db.evaluationDao.watchEntries(fixture.evaluationId).first).single;
    expect(entry.score, 15);
    expect(entry.note, 'Akıcılık gelişiyor.');
  });

  test('zaman damgalı gözlem notları stream üzerinden görünür', () async {
    final fixture = await assessmentFixture();
    await db.evaluationDao.addObservation(
      fixture.evaluationId,
      'Sunuma göz temasıyla başladı.',
    );
    final notes = await db.evaluationDao.watchObservations(fixture.evaluationId).first;
    expect(notes, hasLength(1));
    expect(notes.single.text, 'Sunuma göz temasıyla başladı.');
  });
}
