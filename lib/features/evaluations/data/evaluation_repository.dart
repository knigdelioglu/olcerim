import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/evaluation_dao.dart';
import 'package:olcerim/features/evaluations/domain/assessment_results.dart';

class EvaluationRepository {
  EvaluationRepository(this._database);
  final AppDatabase _database;

  Stream<List<EvaluationStudentRow>> watchStudents(int assessmentId) =>
      _database.evaluationDao.watchStudentsForAssessment(assessmentId);
  Stream<List<EvaluationEntry>> watchEntries(int evaluationId) =>
      _database.evaluationDao.watchEntries(evaluationId);
  Future<List<RubricCriterion>> criteria(int assessmentId) =>
      _database.evaluationDao.criteriaForAssessment(assessmentId);
  Future<List<RubricLevel>> levels(int criterionId) =>
      _database.evaluationDao.levelsForCriterion(criterionId);

  Future<void> score({
    required int evaluationId,
    required int criterionId,
    required double score,
    String? note,
  }) =>
      _database.evaluationDao.upsertScore(
        evaluationId: evaluationId,
        criterionId: criterionId,
        score: score,
        note: note,
      );

  Future<void> saveCriterionNote({
    required int evaluationId,
    required int criterionId,
    String? note,
  }) =>
      _database.evaluationDao.saveCriterionNote(
        evaluationId: evaluationId,
        criterionId: criterionId,
        note: note,
      );

  Future<void> saveStudentNote(int evaluationId, String? note) =>
      _database.evaluationDao.saveStudentNote(evaluationId, note);
  Future<int> addObservation(int evaluationId, String text) =>
      _database.evaluationDao.addObservation(evaluationId, text);
  Stream<List<ObservationNote>> watchObservations(int evaluationId) =>
      _database.evaluationDao.watchObservations(evaluationId);
  Future<AssessmentResults> loadResults(int assessmentId) =>
      _database.evaluationDao.loadResults(assessmentId);
}
