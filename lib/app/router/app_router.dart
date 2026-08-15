enum AppSection {
  students,
  rubrics,
  evaluations,
  reports,
  backup,
}

extension AppSectionLabel on AppSection {
  String get label => switch (this) {
        AppSection.students => 'Öğrenciler',
        AppSection.rubrics => 'Rubrikler',
        AppSection.evaluations => 'Değerlendirme',
        AppSection.reports => 'Raporlar',
        AppSection.backup => 'Yedekleme',
      };
}
