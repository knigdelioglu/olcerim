import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/student_dao.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';
import 'package:olcerim/features/rubrics/domain/rubric_draft.dart';

class DemoRepository {
  DemoRepository(this._database);
  final AppDatabase _database;

  static const int demoStudentCount = 30;

  Future<int> createDemoWorkspace() async {
    final year = await _database.schoolDao.activeSchoolYear();
    if (year == null) throw StateError('Aktif eğitim yılı bulunamadı.');
    final classId = await _database.schoolDao.saveClassroom(
      schoolYearId: year.id,
      name: '10/Demo',
      courseName: 'Türk Dili ve Edebiyatı',
      description: 'Ölçerim özelliklerini gerçek öğrenci verisi kullanmadan denemek için sentetik sınıf.',
    );
    await _database.studentDao.insertMultipleStudents(
      classId,
      List.generate(
        demoStudentCount,
        (index) => StudentImportRecord(
          fullName: 'Demo Öğrenci ${(index + 1).toString().padLeft(2, '0')}',
          schoolNumber: '${100 + index + 1}',
        ),
      ),
    );
    final rubricId = await _database.rubricDao.saveDraft(
      RubricDraft(
        title: 'Sözlü Sunum Demo',
        description: 'Sentetik beta denemesi için örnek rubrik.',
        criteria: [
          CriterionDraft(title: 'İçerik', maxScore: 20, levels: _levels()),
          CriterionDraft(title: 'Akıcılık', maxScore: 20, levels: _levels()),
          CriterionDraft(title: 'Dil kullanımı', maxScore: 20, levels: _levels()),
          CriterionDraft(title: 'Sunum', maxScore: 20, levels: _levels()),
          CriterionDraft(title: 'Süre kullanımı', maxScore: 20, levels: _levels()),
        ],
      ),
    );
    await _database.assessmentDao.createAssessment(
      classroomId: classId,
      rubricId: rubricId,
      type: AssessmentType.rubric,
      title: 'Demo Sözlü Sunum',
      description: 'Beta akışını denemek için sentetik değerlendirme.',
      assessmentDate: DateTime.now(),
    );
    return classId;
  }

  List<LevelDraft> _levels() => [
        LevelDraft(label: 'Çok iyi', score: 20),
        LevelDraft(label: 'İyi', score: 15),
        LevelDraft(label: 'Gelişiyor', score: 10),
        LevelDraft(label: 'Başlangıç', score: 5),
      ];
}
