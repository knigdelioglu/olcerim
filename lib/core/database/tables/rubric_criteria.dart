import 'package:drift/drift.dart';
import 'package:olcerim/core/database/tables/rubrics.dart';

@DataClassName('RubricCriterion')
class RubricCriteria extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get rubricId => integer().references(Rubrics, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  RealColumn get maxScore => real()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
