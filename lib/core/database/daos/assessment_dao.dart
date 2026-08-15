import 'package:drift/drift.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';

part 'assessment_dao.g.dart';

@DriftAccessor(tables: [Assessments, Classrooms, Courses, Students, Evaluations, Rubrics])
class AssessmentDao extends DatabaseAccessor<AppDatabase> with _$AssessmentDaoMixin {
  AssessmentDao(super.db);

  Stream<List<AssessmentSummaryRow>> watchAssessments({String? status}) {
    final completedCount = evaluations.id.count(filter: evaluations.status.equals('completed'));
    final totalCount = evaluations.id.count();
    final query = select(assessments).join([
      innerJoin(classrooms, classrooms.id.equalsExp(assessments.classroomId)),
      innerJoin(courses, courses.id.equalsExp(classrooms.courseId)),
      innerJoin(rubrics, rubrics.id.equalsExp(assessments.rubricId)),
      leftOuterJoin(evaluations, evaluations.assessmentId.equalsExp(assessments.id)),
    ])
      ..where(assessments.archived.equals(false));
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
      final assessmentId = await into(assessments).insert(
        AssessmentsCompanion.insert(
          classroomId: classroomId,
          rubricId: rubricId,
          type: type.storageValue,
          title: title.trim(),
          description: Value(description?.trim().isEmpty == true ? null : description?.trim()),
          assessmentDate: assessmentDate,
        ),
      );
      final classroomStudents = await (select(students)
            ..where((row) => row.classroomId.equals(classroomId) & row.archived.equals(false)))
          .get();
      await batch((batch) {
        batch.insertAll(
          evaluations,
          classroomStudents
              .map((student) => EvaluationsCompanion.insert(assessmentId: assessmentId, studentId: student.id))
              .toList(),
        );
      });
      return assessmentId;
    });
  }

  Future<void> setStatus(int assessmentId, AssessmentStatus status) {
    return (update(assessments)..where((row) => row.id.equals(assessmentId))).write(
      AssessmentsCompanion(
        status: Value(status.storageValue),
        updatedAt: Value(DateTime.now()),
        completedAt: Value(status == AssessmentStatus.completed ? DateTime.now() : null),
      ),
    );
  }

  Future<void> setArchived(int assessmentId, bool archived) {
    return (update(assessments)..where((row) => row.id.equals(assessmentId))).write(
      AssessmentsCompanion(archived: Value(archived), updatedAt: Value(DateTime.now())),
    );
  }
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
  const AssessmentDetailRow({required this.assessment, required this.classroom, required this.course, required this.rubric});
  final Assessment assessment;
  final Classroom classroom;
  final Course course;
  final Rubric rubric;
}
