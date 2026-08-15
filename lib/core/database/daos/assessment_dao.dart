import 'package:drift/drift.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/tables/assessments.dart';
import 'package:olcerim/core/database/tables/classrooms.dart';
import 'package:olcerim/core/database/tables/courses.dart';
import 'package:olcerim/core/database/tables/evaluations.dart';
import 'package:olcerim/core/database/tables/rubric_criteria.dart';
import 'package:olcerim/core/database/tables/rubric_levels.dart';
import 'package:olcerim/core/database/tables/rubrics.dart';
import 'package:olcerim/core/database/tables/students.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';
import 'package:olcerim/features/evaluations/domain/quick_scale.dart';

part 'assessment_dao.g.dart';

@DriftAccessor(tables: [Assessments, Classrooms, Courses, Students, Evaluations, Rubrics, RubricCriteria, RubricLevels])
class AssessmentDao extends DatabaseAccessor<AppDatabase> with _$AssessmentDaoMixin {
  AssessmentDao(super.db);

  Stream<List<AssessmentSummaryRow>> watchAssessments({String? status, bool archived = false}) {
    final completedCount = evaluations.id.count(filter: evaluations.status.equals('completed'));
    final totalCount = evaluations.id.count();
    final query = select(assessments).join([
      innerJoin(classrooms, classrooms.id.equalsExp(assessments.classroomId)),
      innerJoin(courses, courses.id.equalsExp(classrooms.courseId)),
      innerJoin(rubrics, rubrics.id.equalsExp(assessments.rubricId)),
      leftOuterJoin(evaluations, evaluations.assessmentId.equalsExp(assessments.id)),
    ])..where(assessments.archived.equals(archived));
    if (status != null) query.where(assessments.status.equals(status));
    query
      ..addColumns([completedCount, totalCount])
      ..groupBy([assessments.id, classrooms.id, courses.id, rubrics.id])
      ..orderBy([OrderingTerm.desc(assessments.assessmentDate)]);
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => AssessmentSummaryRow(
                  assessment: row.readTable(assessments),
                  classroom: row.readTable(classrooms),
                  course: row.readTable(courses),
                  rubric: row.readTable(rubrics),
                  completedCount: row.read(completedCount) ?? 0,
                  totalCount: row.read(totalCount) ?? 0,
                ),
              )
              .toList(),
        );
  }

  Future<AssessmentDetailRow?> detail(int assessmentId) async {
    final query = select(assessments).join([
      innerJoin(classrooms, classrooms.id.equalsExp(assessments.classroomId)),
      innerJoin(courses, courses.id.equalsExp(classrooms.courseId)),
      innerJoin(rubrics, rubrics.id.equalsExp(assessments.rubricId)),
    ])..where(assessments.id.equals(assessmentId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return AssessmentDetailRow(
      assessment: row.readTable(assessments),
      classroom: row.readTable(classrooms),
      course: row.readTable(courses),
      rubric: row.readTable(rubrics),
    );
  }

  Future<int> createAssessment({
    required int classroomId,
    required int rubricId,
    required AssessmentType type,
    required String title,
    String? description,
    required DateTime assessmentDate,
  }) async {
    return transaction(() async {
      final snapshotRubricId = await _snapshotRubric(rubricId);
      return _insertAssessmentWithEvaluations(
        classroomId: classroomId,
        rubricId: snapshotRubricId,
        type: type,
        title: title,
        description: description,
        assessmentDate: assessmentDate,
      );
    });
  }

  Future<int> createQuickScaleAssessment({
    required int classroomId,
    required QuickScalePreset preset,
    required String title,
    String? description,
    required DateTime assessmentDate,
  }) async {
    return transaction(() async {
      final rubricId = await into(rubrics).insert(
        RubricsCompanion.insert(
          title: 'Hızlı ölçek · ${preset.label}',
          description: Value(preset.description),
          isTemplate: const Value(false),
        ),
      );
      final criterionId = await into(rubricCriteria).insert(
        RubricCriteriaCompanion.insert(
          rubricId: rubricId,
          title: 'Genel değerlendirme',
          description: const Value('Hızlı derecelendirme ölçeğinin tek puanlama boyutu.'),
          maxScore: preset.maxScore,
        ),
      );
      for (var index = 0; index < preset.levels.length; index++) {
        final level = preset.levels[index];
        await into(rubricLevels).insert(
          RubricLevelsCompanion.insert(
            criterionId: criterionId,
            label: level.label,
            score: level.score,
            sortOrder: Value(index),
          ),
        );
      }
      return _insertAssessmentWithEvaluations(
        classroomId: classroomId,
        rubricId: rubricId,
        type: AssessmentType.quickScale,
        title: title,
        description: description,
        assessmentDate: assessmentDate,
      );
    });
  }

  Future<int> _insertAssessmentWithEvaluations({
    required int classroomId,
    required int rubricId,
    required AssessmentType type,
    required String title,
    String? description,
    required DateTime assessmentDate,
  }) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) throw ArgumentError('Değerlendirme adı boş olamaz.');
    final assessmentId = await into(assessments).insert(
      AssessmentsCompanion.insert(
        classroomId: classroomId,
        rubricId: rubricId,
        type: type.storageValue,
        title: normalizedTitle,
        description: Value(description?.trim().isEmpty == true ? null : description?.trim()),
        assessmentDate: assessmentDate,
      ),
    );
    final classroomStudents = await (select(students)
          ..where((row) => row.classroomId.equals(classroomId) & row.archived.equals(false)))
        .get();
    if (classroomStudents.isNotEmpty) {
      await batch(
        (batch) => batch.insertAll(
          evaluations,
          classroomStudents
              .map((student) => EvaluationsCompanion.insert(assessmentId: assessmentId, studentId: student.id))
              .toList(),
        ),
      );
    }
    return assessmentId;
  }

  Future<int> _snapshotRubric(int sourceId) async {
    final source = await (select(rubrics)..where((row) => row.id.equals(sourceId))).getSingle();
    final snapshotId = await into(rubrics).insert(
      RubricsCompanion.insert(
        title: source.title,
        description: Value(source.description),
        isTemplate: const Value(false),
      ),
    );
    final criteria = await (select(rubricCriteria)
          ..where((row) => row.rubricId.equals(sourceId))
          ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
        .get();
    for (final criterion in criteria) {
      final newCriterionId = await into(rubricCriteria).insert(
        RubricCriteriaCompanion.insert(
          rubricId: snapshotId,
          title: criterion.title,
          description: Value(criterion.description),
          maxScore: criterion.maxScore,
          sortOrder: Value(criterion.sortOrder),
        ),
      );
      final levels = await (select(rubricLevels)
            ..where((row) => row.criterionId.equals(criterion.id))
            ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
          .get();
      for (final level in levels) {
        await into(rubricLevels).insert(
          RubricLevelsCompanion.insert(
            criterionId: newCriterionId,
            label: level.label,
            description: Value(level.description),
            score: level.score,
            sortOrder: Value(level.sortOrder),
          ),
        );
      }
    }
    return snapshotId;
  }

  Future<void> setStatus(int assessmentId, AssessmentStatus status) =>
      (update(assessments)..where((row) => row.id.equals(assessmentId))).write(
        AssessmentsCompanion(
          status: Value(status.storageValue),
          updatedAt: Value(DateTime.now()),
          completedAt: Value(status == AssessmentStatus.completed ? DateTime.now() : null),
        ),
      );

  Future<void> setArchived(int assessmentId, bool archived) =>
      (update(assessments)..where((row) => row.id.equals(assessmentId))).write(
        AssessmentsCompanion(archived: Value(archived), updatedAt: Value(DateTime.now())),
      );
}

class AssessmentSummaryRow {
  const AssessmentSummaryRow({
    required this.assessment,
    required this.classroom,
    required this.course,
    required this.rubric,
    required this.completedCount,
    required this.totalCount,
  });
  final Assessment assessment;
  final Classroom classroom;
  final Course course;
  final Rubric rubric;
  final int completedCount;
  final int totalCount;
}

class AssessmentDetailRow {
  const AssessmentDetailRow({
    required this.assessment,
    required this.classroom,
    required this.course,
    required this.rubric,
  });
  final Assessment assessment;
  final Classroom classroom;
  final Course course;
  final Rubric rubric;
}
