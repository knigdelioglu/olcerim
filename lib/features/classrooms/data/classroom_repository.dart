import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/school_dao.dart';

class ClassroomRepository {
  ClassroomRepository(this._database);
  final AppDatabase _database;

  SchoolDao get _dao => _database.schoolDao;

  Stream<List<SchoolYear>> watchSchoolYears() => _dao.watchSchoolYears();
  Future<SchoolYear?> activeSchoolYear() => _dao.activeSchoolYear();

  Future<int> createSchoolYear({
    required String label,
    required DateTime startsAt,
    required DateTime endsAt,
    bool makeActive = false,
  }) =>
      _dao.createSchoolYear(
        label: label,
        startsAt: startsAt,
        endsAt: endsAt,
        makeActive: makeActive,
      );

  Future<void> setActiveSchoolYear(int id) => _dao.setActiveSchoolYear(id);

  Stream<List<ClassroomSummaryRow>> watchClassrooms({int? schoolYearId, bool archived = false}) =>
      _dao.watchClassrooms(schoolYearId: schoolYearId, archived: archived);
  Future<ClassroomDetailRow?> classroomDetail(int id) => _dao.classroomDetail(id);

  Future<int> createClassroom({
    required int schoolYearId,
    required String name,
    required String courseName,
    String? description,
  }) {
    return _dao.saveClassroom(
      schoolYearId: schoolYearId,
      name: name,
      courseName: courseName,
      description: description,
    );
  }

  Future<int> updateClassroom({
    required int id,
    required int schoolYearId,
    required String name,
    required String courseName,
    String? description,
  }) {
    return _dao.saveClassroom(
      id: id,
      schoolYearId: schoolYearId,
      name: name,
      courseName: courseName,
      description: description,
    );
  }

  Future<void> setArchived(int id, bool archived) => _dao.setClassroomArchived(id, archived);
}
