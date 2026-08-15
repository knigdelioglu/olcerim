import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/database_provider.dart';
import 'package:olcerim/features/onboarding/data/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(databaseProvider)),
);

final onboardingCompletedProvider =
    AsyncNotifierProvider<OnboardingController, bool>(OnboardingController.new);

class OnboardingController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(onboardingRepositoryProvider).hasCompleted();

  Future<void> complete() async {
    await ref.read(onboardingRepositoryProvider).complete();
    state = const AsyncData(true);
  }
}
