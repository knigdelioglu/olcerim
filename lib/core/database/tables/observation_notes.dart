import 'package:drift/drift.dart';
import 'package:olcerim/core/database/tables/evaluations.dart';

class ObservationNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get evaluationId => integer().references(Evaluations, #id, onDelete: KeyAction.cascade)();
  TextColumn get text => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
