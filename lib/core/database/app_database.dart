import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:olcerim/core/constants/app_constants.dart';
import 'package:olcerim/core/database/daos/assessment_dao.dart';
import 'package:olcerim/core/database/daos/evaluation_dao.dart';
import 'package:olcerim/core/database/daos/rubric_dao.dart';
import 'package:olcerim/core/database/daos/school_dao.dart';
import 'package:olcerim/core/database/daos/student_dao.dart';
import 'package:olcerim/core/database/tables/assessments.dart';
import 'package:olcerim/core/database/tables/classrooms.dart';
import 'package:olcerim/core/database/tables/courses.dart';
import 'package:olcerim/core/database/tables/evaluation_entries.dart';
import 'package:olcerim/core/database/tables/evaluations.dart';
import 'package:olcerim/core/database/tables/observation_notes.dart';
import 'package:olcerim/core/database/tables/rubric_criteria.dart';
import 'package:olcerim/core/database/tables/rubric_levels.dart';
import 'package:olcerim/core/database/tables/rubrics.dart';
import 'package:olcerim/core/database/tables/school_years.dart';
import 'package:olcerim/core/database/tables/students.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [SchoolYears, Courses, Classrooms, Students, Rubrics, RubricCriteria, RubricLevels, Assessments, Evaluations, EvaluationEntries, ObservationNotes], daos: [SchoolDao, StudentDao, RubricDao, AssessmentDao, EvaluationDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async { await migrator.createAll(); await _seedInitialSchoolYear(); },
        onUpgrade: (migrator, from, to) async {
          if (from < 2) await _migrateV1ToV2(migrator);
          if (from < 3) await _migrateV2ToV3(migrator);
          if (from < 4) {
            await migrator.addColumn(rubrics, rubrics.isTemplate);
            await migrator.addColumn(rubrics, rubrics.archived);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
          final active = await (select(schoolYears)..where((row) => row.isActive.equals(true))).getSingleOrNull();
          if (active == null) await _seedInitialSchoolYear();
        },
      );

  Future<void> _migrateV1ToV2(Migrator migrator) async {
    await customStatement('PRAGMA foreign_keys = OFF');
    await migrator.createTable(schoolYears); await migrator.createTable(courses); await migrator.createTable(classrooms);
    const now = "CAST(strftime('%s','now') AS INTEGER)";
    await customStatement("INSERT INTO school_years (label, starts_at, ends_at, is_active, archived, created_at) VALUES ('İlk Eğitim Yılı', $now, $now, 1, 0, $now)");
    await customStatement("INSERT INTO courses (name, archived, created_at) VALUES ('Ders', 0, $now)");
    await customStatement("CREATE TABLE students_v2 (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, classroom_id INTEGER NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE, school_number TEXT NULL, full_name TEXT NOT NULL, archived INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL DEFAULT ($now), updated_at INTEGER NOT NULL DEFAULT ($now), UNIQUE(classroom_id, school_number))");
    await customStatement("INSERT INTO classrooms (school_year_id, course_id, name, description, archived, created_at, updated_at) SELECT 1, 1, class_name, NULL, 0, $now, $now FROM students GROUP BY class_name");
    await customStatement('INSERT INTO students_v2 (id, classroom_id, school_number, full_name, archived, created_at, updated_at) SELECT s.id, c.id, s.school_number, s.full_name, s.archived, s.created_at, s.created_at FROM students s JOIN classrooms c ON c.name = s.class_name');
    await customStatement('DROP TABLE students'); await customStatement('ALTER TABLE students_v2 RENAME TO students'); await customStatement('PRAGMA foreign_keys = ON');
  }

  Future<void> _migrateV2ToV3(Migrator migrator) async {
    await customStatement('PRAGMA foreign_keys = OFF');
    await migrator.createTable(rubricLevels); await migrator.createTable(assessments); await migrator.createTable(evaluations); await migrator.createTable(observationNotes);
    const now = "CAST(strftime('%s','now') AS INTEGER)";
    await customStatement("CREATE TABLE evaluation_entries_v3 (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, evaluation_id INTEGER NOT NULL REFERENCES evaluations(id) ON DELETE CASCADE, criterion_id INTEGER NOT NULL REFERENCES rubric_criteria(id) ON DELETE CASCADE, score REAL NOT NULL, note TEXT NULL, evaluated_at INTEGER NOT NULL DEFAULT ($now), UNIQUE(evaluation_id, criterion_id))");
    await customStatement("INSERT INTO assessments (classroom_id, rubric_id, type, title, description, assessment_date, status, archived, created_at, updated_at) SELECT DISTINCT s.classroom_id, rc.rubric_id, 'rubric', 'Aktarılan değerlendirme', 'Önceki şemadan korunan değerlendirme', $now, 'active', 0, $now, $now FROM evaluation_entries ee JOIN students s ON s.id = ee.student_id JOIN rubric_criteria rc ON rc.id = ee.criterion_id");
    await customStatement("INSERT INTO evaluations (assessment_id, student_id, note, status, updated_at) SELECT DISTINCT a.id, ee.student_id, NULL, 'incomplete', $now FROM evaluation_entries ee JOIN students s ON s.id = ee.student_id JOIN rubric_criteria rc ON rc.id = ee.criterion_id JOIN assessments a ON a.classroom_id = s.classroom_id AND a.rubric_id = rc.rubric_id AND a.title = 'Aktarılan değerlendirme'");
    await customStatement('INSERT INTO evaluation_entries_v3 (id, evaluation_id, criterion_id, score, note, evaluated_at) SELECT ee.id, e.id, ee.criterion_id, ee.score, ee.note, ee.evaluated_at FROM evaluation_entries ee JOIN students s ON s.id = ee.student_id JOIN rubric_criteria rc ON rc.id = ee.criterion_id JOIN assessments a ON a.classroom_id = s.classroom_id AND a.rubric_id = rc.rubric_id AND a.title = \'Aktarılan değerlendirme\' JOIN evaluations e ON e.assessment_id = a.id AND e.student_id = s.id');
    await customStatement('DROP TABLE evaluation_entries'); await customStatement('ALTER TABLE evaluation_entries_v3 RENAME TO evaluation_entries'); await customStatement('PRAGMA foreign_keys = ON');
  }

  Future<void> _seedInitialSchoolYear() async {
    final now = DateTime.now(); final startYear = now.month >= 8 ? now.year : now.year - 1; final label = '$startYear–${startYear + 1}';
    await into(schoolYears).insert(SchoolYearsCompanion.insert(label: label, startsAt: DateTime(startYear, 9), endsAt: DateTime(startYear + 1, 8, 31), isActive: const Value(true)), mode: InsertMode.insertOrIgnore);
  }
}

LazyDatabase _openConnection() => LazyDatabase(() async { final directory = await getApplicationSupportDirectory(); return NativeDatabase.createInBackground(File(p.join(directory.path, AppConstants.databaseFileName))); });
