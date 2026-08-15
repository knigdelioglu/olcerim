import 'package:olcerim/features/rubrics/data/rubric_repository.dart';
import 'package:olcerim/features/rubrics/domain/rubric_draft.dart';
import 'package:olcerim/features/settings/data/app_settings_repository.dart';

class DefaultTemplateSeeder {
  DefaultTemplateSeeder(this._rubrics, this._settings);
  final RubricRepository _rubrics;
  final AppSettingsRepository _settings;

  Future<void> seedOnce() async {
    if (await _settings.get('defaultTemplatesSeeded') == 'true') return;
    for (final draft in _templates) {
      await _rubrics.save(draft);
    }
    await _settings.set('defaultTemplatesSeeded', 'true');
  }

  List<RubricDraft> get _templates => [
        _rubric('Sözlü Sunum', ['İçerik', 'Akıcılık', 'Dil kullanımı', 'Sunum', 'Süre kullanımı']),
        _rubric('Konuşma Becerisi', ['Anlatım bütünlüğü', 'Akıcılık', 'Telaffuz', 'Kelime kullanımı', 'Etkileşim']),
        _rubric('Proje Değerlendirme', ['Araştırma', 'İçerik doğruluğu', 'Ürün niteliği', 'Süreç yönetimi', 'Sunum']),
        _rubric('Grup Çalışması', ['Katılım', 'İş birliği', 'Sorumluluk', 'İletişim', 'Ortak ürüne katkı']),
        _rubric('Okuma Becerisi', ['Anlama', 'Çıkarım', 'Ana düşünce', 'Kanıt kullanımı', 'Yorumlama']),
        _rubric('Yazma Becerisi', ['İçerik', 'Planlama', 'Dil ve anlatım', 'Yazım ve noktalama', 'Özgünlük']),
      ];

  RubricDraft _rubric(String title, List<String> criteria) => RubricDraft(
        title: title,
        description: 'Ölçerim başlangıç şablonu. İhtiyacınıza göre çoğaltıp düzenleyebilirsiniz.',
        criteria: criteria.map((name) => CriterionDraft(title: name, maxScore: 20)).toList(),
      );
}
