import 'package:flutter/material.dart';

class BackupView extends StatelessWidget {
  const BackupView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Yedekleme', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Tam yedek şifreli ve sürümlü bir dosya olarak dışa aktarılacak.'),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.ios_share),
          label: const Text('Şifreli yedek oluştur'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.settings_backup_restore),
          label: const Text('Yedekten geri yükle'),
        ),
      ],
    );
  }
}
