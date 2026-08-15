import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/database_provider.dart';
import 'package:olcerim/features/settings/data/app_settings_repository.dart';

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>(
  (ref) => AppSettingsRepository(ref.watch(databaseProvider)),
);

final themeModeProvider = AsyncNotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final value = await ref.watch(appSettingsRepositoryProvider).get('themeMode');
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = AsyncData(mode);
    await ref.read(appSettingsRepositoryProvider).set('themeMode', mode.name);
  }
}
