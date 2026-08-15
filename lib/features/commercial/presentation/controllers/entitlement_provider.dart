import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/features/commercial/data/entitlement_repository.dart';
import 'package:olcerim/features/commercial/domain/product_tier.dart';
import 'package:olcerim/features/settings/presentation/controllers/settings_providers.dart';

final entitlementRepositoryProvider = Provider<EntitlementRepository>(
  (ref) => EntitlementRepository(ref.watch(appSettingsRepositoryProvider)),
);

final productTierProvider = FutureProvider<ProductTier>(
  (ref) => ref.watch(entitlementRepositoryProvider).currentTier(),
);
