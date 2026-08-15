import 'package:drift/drift.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/tables/rubric_criteria.dart';
import 'package:olcerim/core/database/tables/rubrics.dart';

part 'rubric_dao.g.dart';

@DriftAccessor(tables: [Rubrics, RubricCriteria])
class RubricDao extends DatabaseAccessor<AppDatabase> with _$RubricDaoMixin {
  RubricDao(super.attachedDatabase);

  Stream<List<Rubric>> watchAllRubrics() {
    return (select(rubrics)..orderBy([(row) => OrderingTerm.asc(row.title)])).watch();
  }

  Future<int> createRubric(RubricsCompanion rubric) => into(rubrics).insert(rubric);
}
