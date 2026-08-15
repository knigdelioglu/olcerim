import 'package:drift/drift.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/tables/students.dart';

part 'student_dao.g.dart';

@DriftAccessor(tables: [Students])
class StudentDao extends DatabaseAccessor<AppDatabase> with _$StudentDaoMixin {
  StudentDao(super.attachedDatabase);

  Stream<List<Student>> watchAllStudents() {
    return (select(students)
          ..where((row) => row.archived.equals(false))
          ..orderBy([(row) => OrderingTerm.asc(row.fullName)]))
        .watch();
  }

  Future<void> insertMultipleStudents(List<StudentsCompanion> rows) async {
    await transaction(() async {
      await batch((batch) {
        batch.insertAll(students, rows, mode: InsertMode.insertOrIgnore);
      });
    });
  }
}
