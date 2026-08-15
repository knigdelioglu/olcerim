import 'package:drift/drift.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/tables/assessments.dart';
import 'package:olcerim/core/database/tables/classrooms.dart';
import 'package:olcerim/core/database/tables/evaluation_entries.dart';
import 'package:olcerim/core/database/tables/evaluations.dart';
import 'package:olcerim/core/database/tables/observation_notes.dart';
import 'package:olcerim/core/database/tables/rubric_criteria.dart';
import 'package:olcerim/core/database/tables/rubric_levels.dart';
import 'package:olcerim/core/database/tables/students.dart';
import 'package:olcerim/features/evaluations/domain/assessment_results.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';

part 'evaluation_dao.g.dart';

@DriftAccessor(tables: [
  Assessments,
  Classrooms,
  Evaluations,
  EvaluationEntries,
  ObservationNotes,
  Students,
  RubricCriteria,
  RubricLevels,
])
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

  Stream<List<EvaluationEntry>> watchEntries(int evaluationId) =>
      (select(evaluationEntries)
            ..where((row) => row.evaluationId.equals(evaluationId))
            ..orderBy([(row) => OrderingTerm.asc(row.criterionId)]))
          .watch();

  Future<List<RubricCriterion>> criteriaForAssessment(int assessmentId) async {
    final assessment = await (select(assessments)..where((row) => row.id.equals(assessmentId))).getSingle();
    return (select(rubricCriteria)
          ..where((row) => row.rubricId.equals(assessment.rubricId))
          ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
        .get();
  }

  Future<List<RubricLevel>> levelsForCriterion(int criterionId) =>
      (select(rubricLevels)
            ..where((row) => row.criterionId.equals(criterionId))
            ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
          .get();

  Future<void> upsertScore({
    required int evaluationId,
    required int criterionId,
    required double score,
    String? note,
  }) async {
    await transaction(() async {
      final criterion = await (select(rubricCriteria)..where((row) => row.id.equals(criterionId))).getSingle();
      if (score < 0 || score > criterion.maxScore) {
        throw ArgumentError.value(score, 'score', 'Puan 0 ile ${criterion.maxScore} arasında olmalıdır.');
      }
      final existing = await (select(evaluationEntries)
            ..where(
              (row) => row.evaluationId.equals(evaluationId) & row.criterionId.equals(criterionId),
            ))
          .getSingleOrNull();
      final normalizedNote = note == null
          ? existing?.note
          : (note.trim().isEmpty ? null : note.trim());
      final now = DateTime.now();
      if (existing == null) {
        await into(evaluationEntries).insert(
          EvaluationEntriesCompanion.insert(
            evaluationId: evaluationId,
            criterionId: criterionId,
            score: score,
            note: Value(normalizedNote),
            evaluatedAt: Value(now),
          ),
        );
      } else {
        await (update(evaluationEntries)..where((row) => row.id.equals(existing.id))).write(
          EvaluationEntriesCompanion(
            score: Value(score),
            note: Value(normalizedNote),
            evaluatedAt: Value(now),
          ),
        );
      }
      await _refreshEvaluationStatus(evaluationId);
    });
  }

  Future<void> saveCriterionNote({
    required int evaluationId,
    required int criterionId,
    String? note,
  }) async {
    final normalized = note?.trim();
    final affected = await (update(evaluationEntries)
          ..where(
            (row) => row.evaluationId.equals(evaluationId) & row.criterionId.equals(criterionId),
          ))
        .write(
      EvaluationEntriesCompanion(
        note: Value(normalized == null || normalized.isEmpty ? null : normalized),
        evaluatedAt: Value(DateTime.now()),
      ),
    );
    if (affected == 0) throw StateError('Kriter notu eklemeden önce puan verin.');
  }

  Future<void> saveStudentNote(int evaluationId, String? note) =>
      (update(evaluations)..where((row) => row.id.equals(evaluationId))).write(
        EvaluationsCompanion(
          note: Value(note?.trim().isEmpty == true ? null : note?.trim()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<int> addObservation(int evaluationId, String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) throw ArgumentError('Gözlem notu boş olamaz.');
    return into(observationNotes).insert(
      ObservationNotesCompanion.insert(evaluationId: evaluationId, content: normalized),
    );
  }

  Stream<List<ObservationNote>> watchObservations(int evaluationId) =>
      (select(observationNotes)
            ..where((row) => row.evaluationId.equals(evaluationId))
            ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
          .watch();

  Future<AssessmentResults> loadResults(int assessmentId) async {
    final assessment = await (select(assessments)..where((row) => row.id.equals(assessmentId))).getSingle();
    final classroom = await (select(classrooms)..where((row) => row.id.equals(assessment.classroomId))).getSingle();
    final criteria = await criteriaForAssessment(assessmentId);
    final evaluationRows = await (select(evaluations).join([
      innerJoin(students, students.id.equalsExp(evaluations.studentId)),
    ])
          ..where(evaluations.assessmentId.equals(assessmentId) & students.archived.equals(false))
          ..orderBy([OrderingTerm.asc(students.schoolNumber), OrderingTerm.asc(students.fullName)]))
        .get();
    final studentResults = <StudentResult>[];
    final criterionScores = <int, List<double>>{for (final criterion in criteria) criterion.id: <double>[]};
    for (final row in evaluationRows) {
      final evaluation = row.readTable(evaluations);
      final student = row.readTable(students);
      final entries = await (select(evaluationEntries)
            ..where((item) => item.evaluationId.equals(evaluation.id))
            ..orderBy([(item) => OrderingTerm.asc(item.criterionId)]))
          .get();
      final observations = await (select(observationNotes)
            ..where((item) => item.evaluationId.equals(evaluation.id))
            ..orderBy([(item) => OrderingTerm.asc(item.createdAt)]))
          .get();
      final mapped = <StudentCriterionResult>[];
      for (final entry in entries) {
        final criterion = criteria.firstWhere((item) => item.id == entry.criterionId);
        criterionScores[criterion.id]!.add(entry.score);
        mapped.add(
          StudentCriterionResult(
            criterionId: criterion.id,
            title: criterion.title,
            score: entry.score,
            maxScore: criterion.maxScore,
            note: entry.note,
          ),
        );
      }
      studentResults.add(
        StudentResult(
          evaluationId: evaluation.id,
          student: student,
          status: evaluation.status,
          note: evaluation.note,
          entries: mapped,
          observations: observations,
        ),
      );
    }
    final criterionResults = criteria.map((criterion) {
      final scores = criterionScores[criterion.id]!;
      final average = scores.isEmpty
          ? 0.0
          : scores.fold<double>(0, (sum, score) => sum + score) / scores.length;
      return CriterionResult(
        criterionId: criterion.id,
        title: criterion.title,
        maxScore: criterion.maxScore,
        average: average,
        scoredCount: scores.length,
      );
    }).toList();
    return AssessmentResults(
      assessment: assessment,
      classroom: classroom,
      criteria: criterionResults,
      students: studentResults,
    );
  }

  Future<void> _refreshEvaluationStatus(int evaluationId) async {
    final evaluation = await (select(evaluations)..where((row) => row.id.equals(evaluationId))).getSingle();
    final assessment = await (select(assessments)..where((row) => row.id.equals(evaluation.assessmentId))).getSingle();
    final criteriaCountExpression = rubricCriteria.id.count();
    final scoredCountExpression = evaluationEntries.id.count();
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
  const EvaluationStudentRow({
    required this.evaluation,
    required this.student,
    required this.scoredCriteria,
  });
  final Evaluation evaluation;
  final Student student;
  final int scoredCriteria;
}
