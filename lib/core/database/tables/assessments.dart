import 'package:drift/drift.dart';
import 'package:olcerim/core/database/tables/classrooms.dart';
import 'package:olcerim/core/database/tables/rubrics.dart';

class Assessments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classroomId => integer().references(Classrooms, #id, onDelete: KeyAction.cascade)();
  IntColumn get rubricId => integer().references(Rubrics, #id)();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get assessmentDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
}
