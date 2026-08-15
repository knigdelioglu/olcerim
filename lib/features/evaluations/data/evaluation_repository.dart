import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/evaluation_dao.dart';

class EvaluationRepository {
  const EvaluationRepository(this._dao);

  final EvaluationDao _dao;

  Stream<List<EvaluationEntry>> watchForStudent(int studentId) {
    return _dao.watchForStudent(studentId);
  }
}
