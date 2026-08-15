import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/features/rubrics/presentation/controllers/rubric_providers.dart';
import 'package:olcerim/features/settings/presentation/controllers/settings_providers.dart';
import 'package:olcerim/features/templates/data/default_template_seeder.dart';

final defaultTemplateSeederProvider = FutureProvider<void>((ref) async {
  final seeder = DefaultTemplateSeeder(
    ref.watch(rubricRepositoryProvider),
    ref.watch(appSettingsRepositoryProvider),
  );
  await seeder.seedOnce();
});
