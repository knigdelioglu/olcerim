import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:olcerim/core/constants/app_constants.dart';
import 'package:olcerim/core/database/daos/assessment_dao.dart';
import 'package:olcerim/core/database/daos/evaluation_dao.dart';
import 'package:olcerim/core/database/daos/rubric_dao.dart';
import 'package:olcerim/core/database/daos/school_dao.dart';
import 'package:olcerim/core/database/daos/student_dao.dart';
import 'package:olcerim/core/database/tables/app_settings.dart';
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

@DriftDatabase(
  tables: [
    SchoolYears,
    Courses,
    Classrooms,
    Students,
    Rubrics,
    RubricCriteria,
    RubricLevels,
    Assessments,
    Evaluations,
    EvaluationEntries,
    ObservationNotes,
    AppSettings,
  ],
  daos: [SchoolDao, StudentDao, RubricDao, AssessmentDao, EvaluationDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
          await _seedInitialSchoolYear();
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 2) await _migrateV1ToV2(migrator);
          if (from < 3) await _migrateV2ToV3(migrator);
          if (from < 4) {
            await migrator.addColumn(rubrics, rubrics.isTemplate);
            await migrator.addColumn(rubrics, rubrics.archived);
          }
          if (from < 5) await migrator.createTable(appSettings);
          if (from < 6) await _repairEvaluationStatuses();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
          final active = await (select(schoolYears)..where((row) => row.isActive.equals(true))).getSingleOrNull();
          if (active == null) await _seedInitialSchoolYear();
        },
      );

  Future<Map<String, dynamic>> exportBackupPayload() async {
    final data = <String, dynamic>{
      'schoolYears': (await select(schoolYears).get()).map((e) => e.toJson()).toList(),
      'courses': (await select(courses).get()).map((e) => e.toJson()).toList(),
      'classrooms': (await select(classrooms).get()).map((e) => e.toJson()).toList(),
      'students': (await select(students).get()).map((e) => e.toJson()).toList(),
      'rubrics': (await select(rubrics).get()).map((e) => e.toJson()).toList(),
      'rubricCriteria': (await select(rubricCriteria).get()).map((e) => e.toJson()).toList(),
      'rubricLevels': (await select(rubricLevels).get()).map((e) => e.toJson()).toList(),
      'assessments': (await select(assessments).get()).map((e) => e.toJson()).toList(),
      'evaluations': (await select(evaluations).get()).map((e) => e.toJson()).toList(),
      'evaluationEntries': (await select(evaluationEntries).get()).map((e) => e.toJson()).toList(),
      'observationNotes': (await select(observationNotes).get()).map((e) => e.toJson()).toList(),
      'appSettings': (await select(appSettings).get()).map((e) => e.toJson()).toList(),
    };
    final counts = <String, int>{
      for (final entry in data.entries) entry.key: (entry.value as List).length,
    };
    return {
      'metadata': {
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'databaseSchemaVersion': schemaVersion,
        'counts': counts,
      },
      'data': data,
    };
  }

  Future<void> restoreBackupData(Map<String, dynamic> data) async {
    List<Map<String, dynamic>> rows(String key) => ((data[key] as List?) ?? const [])
        .cast<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();

    await transaction(() async {
      await delete(observationNotes).go();
      await delete(evaluationEntries).go();
      await delete(evaluations).go();
      await delete(assessments).go();
      await delete(rubricLevels).go();
      await delete(rubricCriteria).go();
      await delete(rubrics).go();
      await delete(students).go();
      await delete(classrooms).go();
      await delete(courses).go();
      await delete(schoolYears).go();
      await delete(appSettings).go();

      for (final row in rows('schoolYears')) {
        final item = SchoolYear.fromJson(row);
        await into(schoolYears).insert(item.toCompanion(true));
      }
      for (final row in rows('courses')) {
        final item = Course.fromJson(row);
        await into(courses).insert(item.toCompanion(true));
      }
      for (final row in rows('classrooms')) {
        final item = Classroom.fromJson(row);
        await into(classrooms).insert(item.toCompanion(true));
      }
      for (final row in rows('students')) {
        final item = Student.fromJson(row);
        await into(students).insert(item.toCompanion(true));
      }
      for (final row in rows('rubrics')) {
        final item = Rubric.fromJson(row);
        await into(rubrics).insert(item.toCompanion(true));
      }
      for (final row in rows('rubricCriteria')) {
        final item = RubricCriterion.fromJson(row);
        await into(rubricCriteria).insert(item.toCompanion(true));
      }
      for (final row in rows('rubricLevels')) {
        final item = RubricLevel.fromJson(row);
        await into(rubricLevels).insert(item.toCompanion(true));
      }
      for (final row in rows('assessments')) {
        final item = Assessment.fromJson(row);
        await into(assessments).insert(item.toCompanion(true));
      }
      for (final row in rows('evaluations')) {
        final item = Evaluation.fromJson(row);
        await into(evaluations).insert(item.toCompanion(true));
      }
      for (final row in rows('evaluationEntries')) {
        final item = EvaluationEntry.fromJson(row);
        await into(evaluationEntries).insert(item.toCompanion(true));
      }
      for (final row in rows('observationNotes')) {
        final item = ObservationNote.fromJson(row);
        await into(observationNotes).insert(item.toCompanion(true));
      }
      for (final row in rows('appSettings')) {
        final item = AppSetting.fromJson(row);
        await into(appSettings).insert(item.toCompanion(true));
      }

      await _repairEvaluationStatuses();
    });
  }

  Future<void> setSetting(String key, String value) => into(appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          key: key,
          value: value,
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<String?> getSetting(String key) async =>
      (await (select(appSettings)..where((row) => row.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _migrateV1ToV2(Migrator migrator) async {
    await customStatement('PRAGMA foreign_keys = OFF');
    await migrator.createTable(schoolYears);
    await migrator.createTable(courses);
    await migrator.createTable(classrooms);
    const now = "CAST(strftime('%s','now') AS INTEGER)";

    await customStatement(
      "INSERT INTO school_years (label, starts_at, ends_at, is_active, archived, created_at) VALUES ('İlk Eğitim Yılı', $now, $now, 1, 0, $now)",
    );
    await customStatement(
      "INSERT INTO courses (name, archived, created_at) VALUES ('Ders', 0, $now)",
    );
    await customStatement(
      'CREATE TABLE students_v2 (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, classroom_id INTEGER NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE, school_number TEXT NULL, full_name TEXT NOT NULL, archived INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL DEFAULT ($now), updated_at INTEGER NOT NULL DEFAULT ($now), UNIQUE(classroom_id, school_number))',
    );
    await customStatement(
      'INSERT INTO classrooms (school_year_id, course_id, name, description, archived, created_at, updated_at) SELECT 1, 1, class_name, NULL, 0, $now, $now FROM students GROUP BY class_name',
    );
    await customStatement(
      'INSERT INTO students_v2 (id, classroom_id, school_number, full_name, archived, created_at, updated_at) SELECT s.id, c.id, s.school_number, s.full_name, s.archived, s.created_at, s.created_at FROM students s JOIN classrooms c ON c.name = s.class_name',
    );
    await customStatement('DROP TABLE students');
    await customStatement('ALTER TABLE students_v2 RENAME TO students');
    await customStatement('PRAGMA foreign_keys = ON');
  }

  Future<void> _migrateV2ToV3(Migrator migrator) async {
    await customStatement('PRAGMA foreign_keys = OFF');
    await migrator.createTable(rubricLevels);
    await migrator.createTable(assessments);
    await migrator.createTable(evaluations);
    await migrator.createTable(observationNotes);
    const now = "CAST(strftime('%s','now') AS INTEGER)";

    await customStatement(
      'CREATE TABLE evaluation_entries_v3 (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, evaluation_id INTEGER NOT NULL REFERENCES evaluations(id) ON DELETE CASCADE, criterion_id INTEGER NOT NULL REFERENCES rubric_criteria(id) ON DELETE CASCADE, score REAL NOT NULL, note TEXT NULL, evaluated_at INTEGER NOT NULL DEFAULT ($now), UNIQUE(evaluation_id, criterion_id))',
    );
    await customStatement(
      "INSERT INTO assessments (classroom_id, rubric_id, type, title, description, assessment_date, status, archived, created_at, updated_at) SELECT DISTINCT s.classroom_id, rc.rubric_id, 'rubric', 'Aktarılan değerlendirme', 'Önceki şemadan korunan değerlendirme', $now, 'active', 0, $now, $now FROM evaluation_entries ee JOIN students s ON s.id = ee.student_id JOIN rubric_criteria rc ON rc.id = ee.criterion_id",
    );
    await customStatement(
      "INSERT INTO evaluations (assessment_id, student_id, note, status, updated_at) SELECT DISTINCT a.id, ee.student_id, NULL, 'incomplete', $now FROM evaluation_entries ee JOIN students s ON s.id = ee.student_id JOIN rubric_criteria rc ON rc.id = ee.criterion_id JOIN assessments a ON a.classroom_id = s.classroom_id AND a.rubric_id = rc.rubric_id AND a.title = 'Aktarılan değerlendirme'",
    );
    await customStatement(
      'INSERT INTO evaluation_entries_v3 (id, evaluation_id, criterion_id, score, note, evaluated_at) SELECT ee.id, e.id, ee.criterion_id, ee.score, ee.note, ee.evaluated_at FROM evaluation_entries ee JOIN students s ON s.id = ee.student_id JOIN rubric_criteria rc ON rc.id = ee.criterion_id JOIN assessments a ON a.classroom_id = s.classroom_id AND a.rubric_id = rc.rubric_id AND a.title = \'Aktarılan değerlendirme\' JOIN evaluations e ON e.assessment_id = a.id AND e.student_id = s.id',
    );
    await customStatement('DROP TABLE evaluation_entries');
    await customStatement('ALTER TABLE evaluation_entries_v3 RENAME TO evaluation_entries');
    await customStatement('PRAGMA foreign_keys = ON');
  }

  Future<void> _repairEvaluationStatuses() async {
    await customStatement('''
      WITH
      entry_counts AS (
        SELECT evaluation_id, COUNT(*) AS entry_count
        FROM evaluation_entries
        GROUP BY evaluation_id
      ),
      criterion_counts AS (
        SELECT a.id AS assessment_id, COUNT(rc.id) AS criterion_count
        FROM assessments a
        LEFT JOIN rubric_criteria rc ON rc.rubric_id = a.rubric_id
        GROUP BY a.id
      ),
      desired_status AS (
        SELECT
          e.id AS evaluation_id,
          CASE
            WHEN COALESCE(ec.entry_count, 0) = 0 THEN 'notStarted'
            WHEN COALESCE(cc.criterion_count, 0) > 0
              AND COALESCE(ec.entry_count, 0) >= cc.criterion_count THEN 'completed'
            ELSE 'incomplete'
          END AS status
        FROM evaluations e
        LEFT JOIN entry_counts ec ON ec.evaluation_id = e.id
        LEFT JOIN criterion_counts cc ON cc.assessment_id = e.assessment_id
      )
      UPDATE evaluations
      SET status = (
        SELECT ds.status
        FROM desired_status ds
        WHERE ds.evaluation_id = evaluations.id
      )
      WHERE EXISTS (
        SELECT 1
        FROM desired_status ds
        WHERE ds.evaluation_id = evaluations.id
          AND ds.status <> evaluations.status
      )
    ''');
  }

  Future<void> _seedInitialSchoolYear() async {
    final now = DateTime.now();
    final startYear = now.month >= 8 ? now.year : now.year - 1;
    await into(schoolYears).insert(
      SchoolYearsCompanion.insert(
        label: '$startYear–${startYear + 1}',
        startsAt: DateTime(startYear, 9),
        endsAt: DateTime(startYear + 1, 8, 31),
        isActive: const Value(true),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final directory = await getApplicationSupportDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(directory.path, AppConstants.databaseFileName)),
      );
    });
