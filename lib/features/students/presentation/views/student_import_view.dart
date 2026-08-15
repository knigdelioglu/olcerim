import 'package:flutter/material.dart';

class StudentImportView extends StatelessWidget {
  const StudentImportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Öğrenciler', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Excel/CSV sınıf listesini içe aktarın ve yerel veritabanında saklayın.'),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.upload_file),
          label: const Text('Excel’den yükle'),
        ),
        const SizedBox(height: 8),
        const Text('Dosya seçme ve isolate tabanlı parse akışı servis katmanına bağlanacak.'),
      ],
    );
  }
}
