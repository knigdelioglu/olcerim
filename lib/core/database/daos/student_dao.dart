import 'package:drift/drift.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/tables/students.dart';

part 'student_dao.g.dart';

@DriftAccessor(tables: [Students])
class StudentDao extends DatabaseAccessor<AppDatabase> with _$StudentDaoMixin {
  StudentDao(super.db);

  Stream<List<Student>> watchStudents(int classroomId, {bool archived = false}) {
    final query = select(students)..where((row) => row.classroomId.equals(classroomId) & row.archived.equals(archived))..orderBy([(row) => OrderingTerm.asc(row.schoolNumber), (row) => OrderingTerm.asc(row.fullName)]);
    return query.watch();
  }

  Stream<List<Student>> watchArchivedStudents() => (select(students)..where((row) => row.archived.equals(true))..orderBy([(row) => OrderingTerm.asc(row.fullName)])).watch();

  Future<List<Student>> studentsForClassroom(int classroomId, {bool includeArchived = false}) { final query = select(students)..where((row) => row.classroomId.equals(classroomId)); if (!includeArchived) query.where((row) => row.archived.equals(false)); return query.get(); }
  Future<int> saveStudent({int? id, required int classroomId, String? schoolNumber, required String fullName}) async { final normalizedNumber = schoolNumber?.trim(); final companion = StudentsCompanion(classroomId: Value(classroomId), schoolNumber: Value(normalizedNumber?.isEmpty == true ? null : normalizedNumber), fullName: Value(fullName.trim()), updatedAt: Value(DateTime.now())); if (id == null) return into(students).insert(companion); await (update(students)..where((row) => row.id.equals(id))).write(companion); return id; }
  Future<void> insertMultipleStudents(int classroomId, List<StudentImportRecord> records) async { await transaction(() async { await batch((batch) { batch.insertAll(students, records.map((row) => StudentsCompanion.insert(classroomId: classroomId, fullName: row.fullName.trim(), schoolNumber: Value(row.schoolNumber?.trim().isEmpty == true ? null : row.schoolNumber?.trim()))).toList(), mode: InsertMode.insert); }); }); }
  Future<void> setArchived(int id, bool archived) => (update(students)..where((row) => row.id.equals(id))).write(StudentsCompanion(archived: Value(archived), updatedAt: Value(DateTime.now())));
}

class StudentImportRecord { const StudentImportRecord({required this.fullName, this.schoolNumber}); final String fullName; final String? schoolNumber; }
