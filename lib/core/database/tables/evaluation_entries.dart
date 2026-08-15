import 'package:drift/drift.dart';
import 'package:olcerim/core/database/tables/evaluations.dart';
import 'package:olcerim/core/database/tables/rubric_criteria.dart';

class EvaluationEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get evaluationId => integer().references(Evaluations, #id, onDelete: KeyAction.cascade)();
  IntColumn get criterionId => integer().references(RubricCriteria, #id, onDelete: KeyAction.cascade)();
  RealColumn get score => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get evaluatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {evaluationId, criterionId},
      ];
}
