import 'package:drift/drift.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/tables/students.dart';

part 'student_dao.g.dart';

@DriftAccessor(tables: [Students])
class StudentDao extends DatabaseAccessor<AppDatabase> with _$StudentDaoMixin {
  StudentDao(super.db);

  Stream<List<Student>> watchStudents(int classroomId, {bool archived = false}) {
    final query = select(students)
      ..where(
        (row) => row.classroomId.equals(classroomId) & row.archived.equals(archived),
      )
      ..orderBy([
        (row) => OrderingTerm.asc(row.schoolNumber),
        (row) => OrderingTerm.asc(row.fullName),
      ]);
    return query.watch();
  }

  Stream<List<Student>> watchArchivedStudents() =>
      (select(students)
            ..where((row) => row.archived.equals(true))
            ..orderBy([(row) => OrderingTerm.asc(row.fullName)]))
          .watch();

  Future<List<Student>> studentsForClassroom(
    int classroomId, {
    bool includeArchived = false,
  }) {
    final query = select(students)
      ..where((row) => row.classroomId.equals(classroomId));
    if (!includeArchived) {
      query.where((row) => row.archived.equals(false));
    }
    return query.get();
  }

  Future<int> saveStudent({
    int? id,
    required int classroomId,
    String? schoolNumber,
    required String fullName,
  }) async {
    final normalizedNumber = _normalizeSchoolNumber(schoolNumber);
    final companion = StudentsCompanion(
      classroomId: Value(classroomId),
      schoolNumber: Value(normalizedNumber),
      fullName: Value(fullName.trim()),
      updatedAt: Value(DateTime.now()),
    );
    if (id == null) return into(students).insert(companion);
    await (update(students)..where((row) => row.id.equals(id))).write(companion);
    return id;
  }

  Future<List<StudentImportConflict>> findImportConflicts(
    int classroomId,
    List<StudentImportRecord> records,
  ) async {
    final schoolNumbers = records
        .map((record) => _normalizeSchoolNumber(record.schoolNumber))
        .whereType<String>()
        .toSet()
        .toList();
    if (schoolNumbers.isEmpty) return const [];

    // Archived students are intentionally included. The database uniqueness
    // invariant applies to the classroom + school-number pair regardless of
    // archive state, so a hidden archived row can still block an insert.
    final existing = await (select(students)
          ..where(
            (row) =>
                row.classroomId.equals(classroomId) &
                row.schoolNumber.isIn(schoolNumbers),
          ))
        .get();
    if (existing.isEmpty) return const [];

    final byNumber = <String, Student>{
      for (final student in existing)
        if (student.schoolNumber case final number?) number: student,
    };
    final conflicts = <StudentImportConflict>[];
    for (final record in records) {
      final number = _normalizeSchoolNumber(record.schoolNumber);
      if (number == null) continue;
      final student = byNumber[number];
      if (student == null) continue;
      conflicts.add(
        StudentImportConflict(
          sourceRow: record.sourceRow,
          schoolNumber: number,
          incomingFullName: record.fullName.trim(),
          existingStudentId: student.id,
          existingFullName: student.fullName,
          existingArchived: student.archived,
        ),
      );
    }
    return conflicts;
  }

  Future<void> insertMultipleStudents(
    int classroomId,
    List<StudentImportRecord> records,
  ) async {
    await transaction(() async {
      // Repeat the preflight inside the write transaction. The UI preflight is
      // for feedback; this check is the data-safety gate against a stale/racy
      // preview or another write that occurred after the preview was shown.
      final conflicts = await findImportConflicts(classroomId, records);
      if (conflicts.isNotEmpty) {
        throw StudentImportConflictException(conflicts);
      }

      await batch((batch) {
        batch.insertAll(
          students,
          records
              .map(
                (row) => StudentsCompanion.insert(
                  classroomId: classroomId,
                  fullName: row.fullName.trim(),
                  schoolNumber: Value(_normalizeSchoolNumber(row.schoolNumber)),
                ),
              )
              .toList(),
          mode: InsertMode.insert,
        );
      });
    });
  }

  Future<void> setArchived(int id, bool archived) =>
      (update(students)..where((row) => row.id.equals(id))).write(
        StudentsCompanion(
          archived: Value(archived),
          updatedAt: Value(DateTime.now()),
        ),
      );

  String? _normalizeSchoolNumber(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

class StudentImportRecord {
  const StudentImportRecord({
    required this.fullName,
    this.schoolNumber,
    this.sourceRow,
  });

  final String fullName;
  final String? schoolNumber;
  final int? sourceRow;
}

class StudentImportConflict {
  const StudentImportConflict({
    required this.sourceRow,
    required this.schoolNumber,
    required this.incomingFullName,
    required this.existingStudentId,
    required this.existingFullName,
    required this.existingArchived,
  });

  final int? sourceRow;
  final String schoolNumber;
  final String incomingFullName;
  final int existingStudentId;
  final String existingFullName;
  final bool existingArchived;

  String get userMessage {
    final rowPrefix = sourceRow == null ? '' : '$sourceRow. satır: ';
    final location = existingArchived ? 'arşivdeki' : 'mevcut';
    return '$rowPrefix$schoolNumber okul numarası $location '
        '$existingFullName öğrencisinde kayıtlı.';
  }
}

class StudentImportConflictException implements Exception {
  const StudentImportConflictException(this.conflicts);

  final List<StudentImportConflict> conflicts;

  @override
  String toString() => conflicts.map((conflict) => conflict.userMessage).join('\n');
}
