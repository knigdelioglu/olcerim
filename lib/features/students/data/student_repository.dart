import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/student_dao.dart';

class StudentRepository {
  StudentRepository(this._database);
  final AppDatabase _database;

  Stream<List<Student>> watchStudents(int classroomId, {bool archived = false}) =>
      _database.studentDao.watchStudents(classroomId, archived: archived);

  Stream<List<Student>> watchArchivedStudents() => _database.studentDao.watchArchivedStudents();

  Future<List<Student>> studentsForClassroom(int classroomId) =>
      _database.studentDao.studentsForClassroom(classroomId);

  Future<int> saveStudent({
    int? id,
    required int classroomId,
    String? schoolNumber,
    required String fullName,
  }) =>
      _database.studentDao.saveStudent(
        id: id,
        classroomId: classroomId,
        schoolNumber: schoolNumber,
        fullName: fullName,
      );

  Future<void> importStudents(int classroomId, List<StudentImportRecord> records) =>
      _database.studentDao.insertMultipleStudents(classroomId, records);

  Future<void> setArchived(int id, bool archived) => _database.studentDao.setArchived(id, archived);
}
