import 'package:drift/drift.dart';
import 'package:olcerim/core/database/tables/evaluations.dart';

class ObservationNotes extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get evaluationId =>
      integer().references(Evaluations, #id, onDelete: KeyAction.cascade)();

  // The Dart getter cannot be named `text`, because that shadows Drift's
  // `text()` column builder. Keep the persisted SQL column name unchanged.
  TextColumn get content => text().named('text')();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
