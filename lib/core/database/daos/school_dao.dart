import 'package:drift/drift.dart';
import 'package:olcerim/core/database/app_database.dart';

part 'school_dao.g.dart';

@DriftAccessor(tables: [SchoolYears, Courses, Classrooms, Students])
class SchoolDao extends DatabaseAccessor<AppDatabase> with _$SchoolDaoMixin {
  SchoolDao(super.db);

  Stream<List<SchoolYear>> watchSchoolYears({bool includeArchived = false}) {
    final query = select(schoolYears)
      ..where((row) => includeArchived ? const Constant(true) : row.archived.equals(false))
      ..orderBy([(row) => OrderingTerm.desc(row.startsAt)]);
    return query.watch();
  }

  Future<SchoolYear?> activeSchoolYear() {
    return (select(schoolYears)..where((row) => row.isActive.equals(true))).getSingleOrNull();
  }

  Future<int> saveSchoolYear(SchoolYearsCompanion value) => into(schoolYears).insert(value);

  Future<void> setActiveSchoolYear(int id) async {
    await transaction(() async {
      await update(schoolYears).write(const SchoolYearsCompanion(isActive: Value(false)));
      await (update(schoolYears)..where((row) => row.id.equals(id))).write(
        const SchoolYearsCompanion(isActive: Value(true)),
      );
    });
  }

  Stream<List<ClassroomSummaryRow>> watchClassrooms({int? schoolYearId, bool archived = false}) {
    final query = select(classrooms).join([
      innerJoin(schoolYears, schoolYears.id.equalsExp(classrooms.schoolYearId)),
      innerJoin(courses, courses.id.equalsExp(classrooms.courseId)),
      leftOuterJoin(students, students.classroomId.equalsExp(classrooms.id) & students.archived.equals(false)),
    ]);
    query.where(classrooms.archived.equals(archived));
    if (schoolYearId != null) query.where(classrooms.schoolYearId.equals(schoolYearId));
    query
      ..addColumns([students.id.count()])
      ..groupBy([classrooms.id, schoolYears.id, courses.id])
      ..orderBy([OrderingTerm.asc(classrooms.name)]);
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => ClassroomSummaryRow(
                  classroom: row.readTable(classrooms),
                  schoolYear: row.readTable(schoolYears),
                  course: row.readTable(courses),
                  studentCount: row.read(students.id.count()) ?? 0,
                ),
              )
              .toList(),
        );
  }

  Future<ClassroomDetailRow?> classroomDetail(int classroomId) async {
    final query = select(classrooms).join([
      innerJoin(schoolYears, schoolYears.id.equalsExp(classrooms.schoolYearId)),
      innerJoin(courses, courses.id.equalsExp(classrooms.courseId)),
    ])..where(classrooms.id.equals(classroomId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return ClassroomDetailRow(
      classroom: row.readTable(classrooms),
      schoolYear: row.readTable(schoolYears),
      course: row.readTable(courses),
    );
  }

  Future<int> ensureCourse(String rawName) async {
    final name = rawName.trim();
    final existing = await (select(courses)..where((row) => row.name.equals(name))).getSingleOrNull();
    if (existing != null) return existing.id;
    return into(courses).insert(CoursesCompanion.insert(name: name));
  }

  Future<int> saveClassroom({
    int? id,
    required int schoolYearId,
    required String name,
    required String courseName,
    String? description,
  }) async {
    return transaction(() async {
      final courseId = await ensureCourse(courseName);
      if (id == null) {
        return into(classrooms).insert(
          ClassroomsCompanion.insert(
            schoolYearId: schoolYearId,
            courseId: courseId,
            name: name.trim(),
            description: Value(description?.trim().isEmpty == true ? null : description?.trim()),
          ),
        );
      }
      await (update(classrooms)..where((row) => row.id.equals(id))).write(
        ClassroomsCompanion(
          schoolYearId: Value(schoolYearId),
          courseId: Value(courseId),
          name: Value(name.trim()),
          description: Value(description?.trim().isEmpty == true ? null : description?.trim()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return id;
    });
  }

  Future<void> setClassroomArchived(int id, bool value) {
    return (update(classrooms)..where((row) => row.id.equals(id))).write(
      ClassroomsCompanion(archived: Value(value), updatedAt: Value(DateTime.now())),
    );
  }
}

class ClassroomSummaryRow {
  const ClassroomSummaryRow({required this.classroom, required this.schoolYear, required this.course, required this.studentCount});
  final Classroom classroom;
  final SchoolYear schoolYear;
  final Course course;
  final int studentCount;
}

class ClassroomDetailRow {
  const ClassroomDetailRow({required this.classroom, required this.schoolYear, required this.course});
  final Classroom classroom;
  final SchoolYear schoolYear;
  final Course course;
}
