import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:olcerim/core/constants/app_constants.dart';
import 'package:olcerim/core/database/daos/evaluation_dao.dart';
import 'package:olcerim/core/database/daos/rubric_dao.dart';
import 'package:olcerim/core/database/daos/school_dao.dart';
import 'package:olcerim/core/database/daos/student_dao.dart';
import 'package:olcerim/core/database/tables/classrooms.dart';
import 'package:olcerim/core/database/tables/courses.dart';
import 'package:olcerim/core/database/tables/evaluation_entries.dart';
import 'package:olcerim/core/database/tables/rubric_criteria.dart';
import 'package:olcerim/core/database/tables/rubrics.dart';
import 'package:olcerim/core/database/tables/school_years.dart';
import 'package:olcerim/core/database/tables/students.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [SchoolYears, Courses, Classrooms, Students, Rubrics, RubricCriteria, EvaluationEntries],
  daos: [SchoolDao, StudentDao, RubricDao, EvaluationDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
          await _seedInitialSchoolYear();
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await customStatement('PRAGMA foreign_keys = OFF');
            await migrator.createTable(schoolYears);
            await migrator.createTable(courses);
            await migrator.createTable(classrooms);
            await customStatement("INSERT INTO school_years (label, starts_at, ends_at, is_active, archived, created_at) VALUES ('İlk Eğitim Yılı', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1, 0, CURRENT_TIMESTAMP)");
            await customStatement("INSERT INTO courses (name, archived, created_at) VALUES ('Ders', 0, CURRENT_TIMESTAMP)");
            await customStatement('CREATE TABLE students_v2 (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, classroom_id INTEGER NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE, school_number TEXT NULL, full_name TEXT NOT NULL, archived INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL DEFAULT (strftime(\'%s\', \'now\')), updated_at INTEGER NOT NULL DEFAULT (strftime(\'%s\', \'now\')), UNIQUE(classroom_id, school_number))');
            await customStatement("INSERT INTO classrooms (school_year_id, course_id, name, archived, created_at, updated_at) SELECT 1, 1, class_name, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM students GROUP BY class_name");
            await customStatement('INSERT INTO students_v2 (id, classroom_id, school_number, full_name, archived, created_at, updated_at) SELECT s.id, c.id, s.school_number, s.full_name, s.archived, s.created_at, s.created_at FROM students s JOIN classrooms c ON c.name = s.class_name');
            await customStatement('DROP TABLE students');
            await customStatement('ALTER TABLE students_v2 RENAME TO students');
            await customStatement('PRAGMA foreign_keys = ON');
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
          if (details.wasCreated) return;
          final active = await (select(schoolYears)..where((row) => row.isActive.equals(true))).getSingleOrNull();
          if (active == null) await _seedInitialSchoolYear();
        },
      );

  Future<void> _seedInitialSchoolYear() async {
    final now = DateTime.now();
    final startYear = now.month >= 8 ? now.year : now.year - 1;
    final label = '$startYear–${startYear + 1}';
    await into(schoolYears).insert(
      SchoolYearsCompanion.insert(
        label: label,
        startsAt: DateTime(startYear, 9, 1),
        endsAt: DateTime(startYear + 1, 8, 31),
        isActive: const Value(true),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, AppConstants.databaseFileName));
    return NativeDatabase.createInBackground(file);
  });
}
