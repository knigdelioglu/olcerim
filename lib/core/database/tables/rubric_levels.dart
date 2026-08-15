import 'package:drift/drift.dart';
import 'package:olcerim/core/database/tables/rubric_criteria.dart';

class RubricLevels extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get criterionId => integer().references(RubricCriteria, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text()();
  TextColumn get description => text().nullable()();
  RealColumn get score => real()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
