import 'package:olcerim/core/database/app_database.dart';

class OnboardingRepository {
  OnboardingRepository(this._database);

  static const completedKey = 'hasCompletedOnboarding';

  final AppDatabase _database;

  Future<bool> hasCompleted() async {
    final stored = await _database.getSetting(completedKey);
    if (stored != null) return stored == 'true';

    // Backward compatibility for installs created before onboarding state
    // became persistent. Any existing classroom, including an archived one,
    // means the user has already completed initial setup.
    final existingClassroom =
        await (_database.select(_database.classrooms)..limit(1)).getSingleOrNull();
    if (existingClassroom != null) {
      await complete();
      return true;
    }

    return false;
  }

  Future<void> complete() => _database.setSetting(completedKey, 'true');
}
