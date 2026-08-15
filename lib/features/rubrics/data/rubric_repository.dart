import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/rubric_dao.dart';
import 'package:olcerim/features/rubrics/domain/rubric_draft.dart';

class RubricRepository {
  RubricRepository(this._database);
  final AppDatabase _database;

  Stream<List<RubricSummaryRow>> watchTemplates({bool archived = false}) => _database.rubricDao.watchTemplates(archived: archived);
  Stream<List<Rubric>> watchAllRubrics() => _database.rubricDao.watchAllRubrics();
  Future<RubricDraft?> load(int id) => _database.rubricDao.loadDraft(id);
  Future<int> save(RubricDraft draft) => _database.rubricDao.saveDraft(draft);
  Future<int> duplicate(int id) => _database.rubricDao.duplicate(id);
  Future<void> setArchived(int id, bool archived) => _database.rubricDao.setArchived(id, archived);
}
