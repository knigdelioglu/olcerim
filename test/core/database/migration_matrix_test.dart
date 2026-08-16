import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  for (final version in [2, 3, 4, 5]) {
    test('v$version veritabanı güncel şemaya veri kaybetmeden yükselir', () async {
      await _runMigrationCase(version);
    });
  }
}

Future<void> _runMigrationCase(int version) async {
  final directory = await Directory.systemTemp.createTemp('olcerim-migration-v$version-');
  final file = File('${directory.path}/v$version.sqlite');
  final raw = sqlite3.open(file.path);
  raw.execute('PRAGMA foreign_keys = OFF');

  if (version == 2) {
    _createV2Fixture(raw);
  } else {
    _createV3PlusFixture(
      raw,
      rubricHasV4Columns: version >= 4,
      hasAppSettings: version >= 5,
    );
  }
  raw.execute('PRAGMA user_version = $version');
  raw.close();

  final db = AppDatabase.forTesting(NativeDatabase(file));
  try {
    final students = await db.studentDao.studentsForClassroom(1);
    expect(students, hasLength(1));
    expect(students.single.fullName, 'Sentetik Öğrenci v$version');

    final assessments = await db.assessmentDao.watchAssessments().first;
    expect(assessments, hasLength(1));
    final results = await db.evaluationDao.loadResults(assessments.single.assessment.id);
    expect(results.students, hasLength(1));
    expect(results.students.single.total, version == 2 ? 17 : 18);
    expect(results.students.single.status, 'completed');

    if (version >= 3) {
      expect(results.students.single.note, 'Öğretmen notu v$version');
      expect(results.students.single.observations.single.content, 'Gözlem v$version');
    }

    await db.setSetting('migrationProbe', 'v$version-ok');
    expect(await db.getSetting('migrationProbe'), 'v$version-ok');

    final userVersion = await db.customSelect('PRAGMA user_version').getSingle();
    expect(userVersion.data['user_version'], db.schemaVersion);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  } finally {
    await db.close();
    await directory.delete(recursive: true);
  }
}

void _createV2Fixture(Database db) {
  _createCoreTables(db, rubricHasV4Columns: false);
  db.execute('''
    CREATE TABLE evaluation_entries (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
      criterion_id INTEGER NOT NULL REFERENCES rubric_criteria(id) ON DELETE CASCADE,
      score REAL NOT NULL,
      note TEXT NULL,
      evaluated_at INTEGER NOT NULL,
      UNIQUE(student_id, criterion_id)
    )
  ''');
  _seedCore(db, version: 2, rubricHasV4Columns: false);
  db.execute("INSERT INTO evaluation_entries (id, student_id, criterion_id, score, note, evaluated_at) VALUES (1, 1, 1, 17, 'Kriter notu v2', 1700000000)");
}

void _createV3PlusFixture(
  Database db, {
  required bool rubricHasV4Columns,
  required bool hasAppSettings,
}) {
  _createCoreTables(db, rubricHasV4Columns: rubricHasV4Columns);
  db.execute('''
    CREATE TABLE rubric_levels (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      criterion_id INTEGER NOT NULL REFERENCES rubric_criteria(id) ON DELETE CASCADE,
      label TEXT NOT NULL,
      description TEXT NULL,
      score REAL NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0
    )
  ''');
  db.execute('''
    CREATE TABLE assessments (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      classroom_id INTEGER NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
      rubric_id INTEGER NOT NULL REFERENCES rubrics(id),
      type TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT NULL,
      assessment_date INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'draft',
      archived INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      completed_at INTEGER NULL
    )
  ''');
  db.execute('''
    CREATE TABLE evaluations (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      assessment_id INTEGER NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
      student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
      note TEXT NULL,
      status TEXT NOT NULL DEFAULT 'notStarted',
      updated_at INTEGER NOT NULL,
      UNIQUE(assessment_id, student_id)
    )
  ''');
  db.execute('''
    CREATE TABLE evaluation_entries (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      evaluation_id INTEGER NOT NULL REFERENCES evaluations(id) ON DELETE CASCADE,
      criterion_id INTEGER NOT NULL REFERENCES rubric_criteria(id) ON DELETE CASCADE,
      score REAL NOT NULL,
      note TEXT NULL,
      evaluated_at INTEGER NOT NULL,
      UNIQUE(evaluation_id, criterion_id)
    )
  ''');
  db.execute('''
    CREATE TABLE observation_notes (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      evaluation_id INTEGER NOT NULL REFERENCES evaluations(id) ON DELETE CASCADE,
      text TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''');
  if (hasAppSettings) {
    db.execute('''
      CREATE TABLE app_settings (
        key TEXT NOT NULL PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  final version = hasAppSettings ? 5 : (rubricHasV4Columns ? 4 : 3);
  _seedCore(db, version: version, rubricHasV4Columns: rubricHasV4Columns);
  db.execute("INSERT INTO rubric_levels (id, criterion_id, label, description, score, sort_order) VALUES (1, 1, 'Tam', 'Beklenen başarı', 20, 0)");
  db.execute("INSERT INTO assessments (id, classroom_id, rubric_id, type, title, description, assessment_date, status, archived, created_at, updated_at, completed_at) VALUES (1, 1, 1, 'rubric', 'Sentetik değerlendirme v$version', 'Migration fixture', 1700000000, 'active', 0, 1700000000, 1700000000, NULL)");
  db.execute("INSERT INTO evaluations (id, assessment_id, student_id, note, status, updated_at) VALUES (1, 1, 1, 'Öğretmen notu v$version', 'incomplete', 1700000000)");
  db.execute("INSERT INTO evaluation_entries (id, evaluation_id, criterion_id, score, note, evaluated_at) VALUES (1, 1, 1, 18, 'Kriter notu v$version', 1700000000)");
  db.execute("INSERT INTO observation_notes (id, evaluation_id, text, created_at) VALUES (1, 1, 'Gözlem v$version', 1700000000)");
  if (hasAppSettings) {
    db.execute("INSERT INTO app_settings (key, value, updated_at) VALUES ('themeMode', 'dark', 1700000000)");
  }
}

void _createCoreTables(Database db, {required bool rubricHasV4Columns}) {
  db.execute('''
    CREATE TABLE school_years (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      label TEXT NOT NULL,
      starts_at INTEGER NOT NULL,
      ends_at INTEGER NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 0,
      archived INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      UNIQUE(label)
    )
  ''');
  db.execute('''
    CREATE TABLE courses (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      archived INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      UNIQUE(name)
    )
  ''');
  db.execute('''
    CREATE TABLE classrooms (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      school_year_id INTEGER NOT NULL REFERENCES school_years(id),
      course_id INTEGER NOT NULL REFERENCES courses(id),
      name TEXT NOT NULL,
      description TEXT NULL,
      archived INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      UNIQUE(school_year_id, course_id, name)
    )
  ''');
  db.execute('''
    CREATE TABLE students (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      classroom_id INTEGER NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
      school_number TEXT NULL,
      full_name TEXT NOT NULL,
      archived INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      UNIQUE(classroom_id, school_number)
    )
  ''');
  db.execute('''
    CREATE TABLE rubrics (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT NULL,
      ${rubricHasV4Columns ? 'is_template INTEGER NOT NULL DEFAULT 1, archived INTEGER NOT NULL DEFAULT 0,' : ''}
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE rubric_criteria (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      rubric_id INTEGER NOT NULL REFERENCES rubrics(id) ON DELETE CASCADE,
      title TEXT NOT NULL,
      description TEXT NULL,
      max_score REAL NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0
    )
  ''');
}

void _seedCore(Database db, {required int version, required bool rubricHasV4Columns}) {
  db.execute("INSERT INTO school_years (id, label, starts_at, ends_at, is_active, archived, created_at) VALUES (1, '2026–2027', 1700000000, 1800000000, 1, 0, 1700000000)");
  db.execute("INSERT INTO courses (id, name, archived, created_at) VALUES (1, 'Türk Dili ve Edebiyatı', 0, 1700000000)");
  db.execute("INSERT INTO classrooms (id, school_year_id, course_id, name, description, archived, created_at, updated_at) VALUES (1, 1, 1, '10/Test', 'Migration fixture', 0, 1700000000, 1700000000)");
  db.execute("INSERT INTO students (id, classroom_id, school_number, full_name, archived, created_at, updated_at) VALUES (1, 1, '101', 'Sentetik Öğrenci v$version', 0, 1700000000, 1700000000)");
  if (rubricHasV4Columns) {
    db.execute("INSERT INTO rubrics (id, title, description, is_template, archived, created_at, updated_at) VALUES (1, 'Sentetik Rubrik v$version', 'Migration fixture', 1, 0, 1700000000, 1700000000)");
  } else {
    db.execute("INSERT INTO rubrics (id, title, description, created_at, updated_at) VALUES (1, 'Sentetik Rubrik v$version', 'Migration fixture', 1700000000, 1700000000)");
  }
  db.execute("INSERT INTO rubric_criteria (id, rubric_id, title, description, max_score, sort_order) VALUES (1, 1, 'İçerik', 'Migration fixture', 20, 0)");
}
