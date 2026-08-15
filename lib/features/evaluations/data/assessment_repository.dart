import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/assessment_dao.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';

class AssessmentRepository {
  AssessmentRepository(this._database);
  final AppDatabase _database;

  Stream<List<AssessmentSummaryRow>> watchAssessments({String? status, bool archived = false}) =>
      _database.assessmentDao.watchAssessments(status: status, archived: archived);

  Future<AssessmentDetailRow?> detail(int id) => _database.assessmentDao.detail(id);

  Future<int> create({
    required int classroomId,
    required int rubricId,
    required AssessmentType type,
    required String title,
    String? description,
    required DateTime assessmentDate,
  }) =>
      _database.assessmentDao.createAssessment(
        classroomId: classroomId,
        rubricId: rubricId,
        type: type,
        title: title,
        description: description,
        assessmentDate: assessmentDate,
      );

  Future<void> setStatus(int id, AssessmentStatus status) => _database.assessmentDao.setStatus(id, status);
  Future<void> setArchived(int id, bool archived) => _database.assessmentDao.setArchived(id, archived);
}
