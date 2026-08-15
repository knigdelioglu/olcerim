import 'package:drift/drift.dart';
import 'package:olcerim/core/database/tables/classrooms.dart';

class Students extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classroomId => integer().references(Classrooms, #id, onDelete: KeyAction.cascade)();
  TextColumn get schoolNumber => text().nullable()();
  TextColumn get fullName => text()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {classroomId, schoolNumber},
      ];
}
