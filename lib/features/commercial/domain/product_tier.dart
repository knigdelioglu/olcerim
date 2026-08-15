enum ProductTier { free, pro }

enum ProFeature {
  unlimitedClassrooms,
  unlimitedRubrics,
  advancedRubricLevels,
  pdfExport,
  spreadsheetExport,
  advancedResults,
}

abstract final class CommercialPolicy {
  static const freeActiveClassroomLimit = 1;
  static const freeRubricLimit = 2;

  /// Faz 12 beta kapısı: Gerçek öğretmen beta PASS olmadan ücretli kısıtlar
  /// kullanıcı akışına uygulanmaz ve paywall gösterilmez.
  static const monetizationEnabled = false;

  static bool featureAllowed(ProductTier tier, ProFeature feature) {
    if (!monetizationEnabled) return true;
    return tier == ProductTier.pro;
  }

  /// Backup/restore kullanıcı verisinin güvenlik katmanıdır. Monetizasyon daha
  /// sonra aktive edilse bile restore hiçbir zaman entitlement kaybı nedeniyle
  /// engellenmez.
  static bool get restoreAlwaysAllowed => true;
}
