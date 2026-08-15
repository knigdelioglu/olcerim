import 'package:drift/drift.dart';
import 'package:olcerim/core/database/tables/courses.dart';
import 'package:olcerim/core/database/tables/school_years.dart';

class Classrooms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get schoolYearId => integer().references(SchoolYears, #id)();
  IntColumn get courseId => integer().references(Courses, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {schoolYearId, courseId, name},
      ];
}
