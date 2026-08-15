import 'package:drift/drift.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';

part 'evaluation_dao.g.dart';

@DriftAccessor(tables: [Assessments, Evaluations, EvaluationEntries, ObservationNotes, Students, RubricCriteria])
class EvaluationDao extends DatabaseAccessor<AppDatabase> with _$EvaluationDaoMixin {
  EvaluationDao(super.db);

  Stream<List<EvaluationStudentRow>> watchStudentsForAssessment(int assessmentId) {
    final scoredCount = evaluationEntries.id.count();
    final query = select(evaluations).join([
      innerJoin(students, students.id.equalsExp(evaluations.studentId)),
      leftOuterJoin(evaluationEntries, evaluationEntries.evaluationId.equalsExp(evaluations.id)),
    ])
      ..where(evaluations.assessmentId.equals(assessmentId) & students.archived.equals(false))
      ..addColumns([scoredCount])
      ..groupBy([evaluations.id, students.id])
      ..orderBy([OrderingTerm.asc(students.schoolNumber), OrderingTerm.asc(students.fullName)]);
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => EvaluationStudentRow(
                  evaluation: row.readTable(evaluations),
                  student: row.readTable(students),
                  scoredCriteria: row.read(scoredCount) ?? 0,
                ),
              )
              .toList(),
        );
  }

  Stream<List<EvaluationEntry>> watchEntries(int evaluationId) {
    return (select(evaluationEntries)
          ..where((row) => row.evaluationId.equals(evaluationId))
          ..orderBy([(row) => OrderingTerm.asc(row.criterionId)]))
        .watch();
  }

  Future<List<RubricCriterion>> criteriaForAssessment(int assessmentId) async {
    final assessment = await (select(assessments)..where((row) => row.id.equals(assessmentId))).getSingle();
    return (select(rubricCriteria)
          ..where((row) => row.rubricId.equals(assessment.rubricId))
          ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
        .get();
  }

  Future<void> upsertScore({required int evaluationId, required int criterionId, required double score, String? note}) async {
    await transaction(() async {
      final criterion = await (select(rubricCriteria)..where((row) => row.id.equals(criterionId))).getSingle();
      if (score < 0 || score > criterion.maxScore) {
        throw ArgumentError.value(score, 'score', 'Puan 0 ile ${criterion.maxScore} arasında olmalıdır.');
      }
      await into(evaluationEntries).insertOnConflictUpdate(
        EvaluationEntriesCompanion.insert(
          evaluationId: evaluationId,
          criterionId: criterionId,
          score: score,
          note: Value(note?.trim().isEmpty == true ? null : note?.trim()),
          evaluatedAt: Value(DateTime.now()),
        ),
      );
      await _refreshEvaluationStatus(evaluationId);
    });
  }

  Future<void> saveStudentNote(int evaluationId, String? note) {
    return (update(evaluations)..where((row) => row.id.equals(evaluationId))).write(
      EvaluationsCompanion(note: Value(note?.trim().isEmpty == true ? null : note?.trim()), updatedAt: Value(DateTime.now())),
    );
  }

  Future<int> addObservation(int evaluationId, String text) {
    return into(observationNotes).insert(
      ObservationNotesCompanion.insert(evaluationId: evaluationId, text: text.trim()),
    );
  }

  Stream<List<ObservationNote>> watchObservations(int evaluationId) {
    return (select(observationNotes)
          ..where((row) => row.evaluationId.equals(evaluationId))
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .watch();
  }

  Future<void> _refreshEvaluationStatus(int evaluationId) async {
    final evaluation = await (select(evaluations)..where((row) => row.id.equals(evaluationId))).getSingle();
    final criteriaCountExpression = rubricCriteria.id.count();
    final scoredCountExpression = evaluationEntries.id.count();
    final assessment = await (select(assessments)..where((row) => row.id.equals(evaluation.assessmentId))).getSingle();
    final criteriaCount = await (selectOnly(rubricCriteria)
          ..addColumns([criteriaCountExpression])
          ..where(rubricCriteria.rubricId.equals(assessment.rubricId)))
        .map((row) => row.read(criteriaCountExpression) ?? 0)
        .getSingle();
    final scoredCount = await (selectOnly(evaluationEntries)
          ..addColumns([scoredCountExpression])
          ..where(evaluationEntries.evaluationId.equals(evaluationId)))
        .map((row) => row.read(scoredCountExpression) ?? 0)
        .getSingle();
    final status = scoredCount == 0
        ? EvaluationStatus.notStarted
        : scoredCount >= criteriaCount && criteriaCount > 0
            ? EvaluationStatus.completed
            : EvaluationStatus.incomplete;
    await (update(evaluations)..where((row) => row.id.equals(evaluationId))).write(
      EvaluationsCompanion(status: Value(status.storageValue), updatedAt: Value(DateTime.now())),
    );
  }
}

class EvaluationStudentRow {
  const EvaluationStudentRow({required this.evaluation, required this.student, required this.scoredCriteria});
  final Evaluation evaluation;
  final Student student;
  final int scoredCriteria;
}
