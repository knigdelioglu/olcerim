import 'package:drift/drift.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/tables/evaluation_entries.dart';

part 'evaluation_dao.g.dart';

@DriftAccessor(tables: [EvaluationEntries])
class EvaluationDao extends DatabaseAccessor<AppDatabase> with _$EvaluationDaoMixin {
  EvaluationDao(super.attachedDatabase);

  Stream<List<EvaluationEntry>> watchForStudent(int studentId) {
    return (select(evaluationEntries)
          ..where((row) => row.studentId.equals(studentId))
          ..orderBy([(row) => OrderingTerm.asc(row.criterionId)]))
        .watch();
  }

  Future<void> upsert(EvaluationEntriesCompanion entry) {
    return into(evaluationEntries).insertOnConflictUpdate(entry);
  }
}
