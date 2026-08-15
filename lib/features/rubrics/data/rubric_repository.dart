import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/rubric_dao.dart';

class RubricRepository {
  const RubricRepository(this._dao);

  final RubricDao _dao;

  Stream<List<Rubric>> watchAll() => _dao.watchAllRubrics();
}
