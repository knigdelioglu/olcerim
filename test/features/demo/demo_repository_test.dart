import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/features/demo/data/demo_repository.dart';

void main() {
  late AppDatabase db;
  late DemoRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DemoRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('beta demo workspace creates the full 30-student grading fixture', () async {
    final classroomId = await repository.createDemoWorkspace();

    final students = await db.studentDao.studentsForClassroom(classroomId);
    expect(students, hasLength(DemoRepository.demoStudentCount));
    expect(students.first.fullName, 'Demo Öğrenci 01');
    expect(students.first.schoolNumber, '101');
    expect(students.last.fullName, 'Demo Öğrenci 30');
    expect(students.last.schoolNumber, '130');

    final assessments = await db.assessmentDao.watchAssessments().first;
    final assessment = assessments.singleWhere(
      (item) => item.classroom.id == classroomId,
    );
    expect(assessment.assessment.title, 'Demo Sözlü Sunum');
    expect(assessment.totalCount, DemoRepository.demoStudentCount);
    expect(assessment.completedCount, 0);

    final criteria = await db.evaluationDao.criteriaForAssessment(assessment.assessment.id);
    expect(criteria, hasLength(5));
    expect(criteria.map((item) => item.title), [
      'İçerik',
      'Akıcılık',
      'Dil kullanımı',
      'Sunum',
      'Süre kullanımı',
    ]);
    expect(criteria.fold<double>(0, (sum, item) => sum + item.maxScore), 100);

    for (final criterion in criteria) {
      final levels = await db.evaluationDao.levelsForCriterion(criterion.id);
      expect(levels, hasLength(4));
      expect(levels.map((item) => item.label), [
        'Çok iyi',
        'İyi',
        'Gelişiyor',
        'Başlangıç',
      ]);
    }

    final evaluations =
        await db.evaluationDao.watchStudentsForAssessment(assessment.assessment.id).first;
    expect(evaluations, hasLength(DemoRepository.demoStudentCount));
    expect(evaluations.every((item) => item.evaluation.status == 'notStarted'), isTrue);
  });
}
