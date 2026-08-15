import 'package:drift/drift.dart';
import 'package:olcerim/core/database/tables/assessments.dart';
import 'package:olcerim/core/database/tables/students.dart';

class Evaluations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assessmentId => integer().references(Assessments, #id, onDelete: KeyAction.cascade)();
  IntColumn get studentId => integer().references(Students, #id, onDelete: KeyAction.cascade)();
  TextColumn get note => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('notStarted'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {assessmentId, studentId},
      ];
}
