import 'package:olcerim/features/commercial/domain/product_tier.dart';
import 'package:olcerim/features/settings/data/app_settings_repository.dart';

class EntitlementRepository {
  EntitlementRepository(this._settings);
  final AppSettingsRepository _settings;

  Future<ProductTier> currentTier() async {
    final stored = await _settings.get('productTier');
    return stored == ProductTier.pro.name ? ProductTier.pro : ProductTier.free;
  }

  Future<void> cacheVerifiedTier(ProductTier tier) {
    return _settings.set('productTier', tier.name);
  }

  Future<void> clearCachedEntitlement() {
    return _settings.set('productTier', ProductTier.free.name);
  }
}
