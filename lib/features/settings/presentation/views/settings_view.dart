import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/constants/app_constants.dart';
import 'package:olcerim/features/backup/presentation/views/backup_view.dart';
import 'package:olcerim/features/settings/presentation/controllers/settings_providers.dart';
import 'package:olcerim/features/settings/presentation/views/archives_view.dart';
import 'package:olcerim/features/settings/presentation/views/school_years_view.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const _SectionTitle('Görünüm'),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Tema'),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Açık')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Koyu')),
                  ],
                  selected: {mode},
                  onSelectionChanged: (values) =>
                      ref.read(themeModeProvider.notifier).setMode(values.first),
                ),
              ),
            ),
            const Divider(height: 28),
            const _SectionTitle('Akademik dönem'),
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Eğitim yılları'),
              subtitle: const Text('Yeni eğitim yılı oluşturun ve aktif dönemi seçin.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SchoolYearsView()),
              ),
            ),
            const Divider(height: 28),
            const _SectionTitle('Veri'),
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Yedekleme ve geri yükleme'),
              subtitle: const Text('Şifreli tam yedek oluşturun veya mevcut yedeği geri yükleyin.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupView()),
              ),
            ),
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Arşivlenen veriler'),
              subtitle: const Text('Sınıf, öğrenci, rubrik ve değerlendirmeleri geri yükleyin.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArchivesView()),
              ),
            ),
            const Divider(height: 28),
            const _SectionTitle('Uygulama'),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Hakkında Ölçerim'),
              subtitle: Text('Yerel-öncelikli öğretmen performans değerlendirme uygulaması.'),
            ),
            const ListTile(
              leading: Icon(Icons.tag),
              title: Text('Sürüm'),
              subtitle: Text(AppConstants.appVersion),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Gizlilik'),
              subtitle: const Text('Öğrenci verileri varsayılan olarak cihazınızda kalır.'),
              onTap: () => _info(
                context,
                'Gizlilik',
                'Ölçerim 1.0 hesap veya bulut senkronizasyonu kullanmaz. Öğrenci ve değerlendirme verileri cihazdaki yerel veritabanında saklanır. Dışa aktarma ve yedekleme yalnız sizin başlattığınız sistem paylaşım akışlarıyla yapılır.',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Destek'),
              subtitle: const Text('Kullanım ve hata bildirimi bilgileri'),
              onTap: () => _info(
                context,
                'Destek',
                'Sorun bildirirken gerçek öğrenci verilerini veya yedek dosyanızı paylaşmayın. Uygulama sürümü ve sorunun oluştuğu ekranı belirtmeniz yeterlidir.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _info(BuildContext context, String title, String text) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
