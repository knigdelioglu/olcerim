import 'package:drift/drift.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/student_dao.dart';
import 'package:olcerim/core/services/excel_service.dart';

class StudentRepository {
  const StudentRepository(this._dao);

  final StudentDao _dao;

  Stream<List<Student>> watchAll() => _dao.watchAllStudents();

  Future<void> importStudents(List<ImportedStudent> students) {
    final rows = students
        .map(
          (student) => StudentsCompanion.insert(
            fullName: student.fullName,
            className: student.className,
            schoolNumber: Value(student.schoolNumber),
          ),
        )
        .toList(growable: false);
    return _dao.insertMultipleStudents(rows);
  }
}
