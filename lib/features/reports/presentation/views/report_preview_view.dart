import 'package:flutter/material.dart';

class ReportPreviewView extends StatelessWidget {
  const ReportPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Raporlar', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('PDF/Excel değerlendirme çizelgesi önizleme, paylaşma ve yazdırma alanı.'),
        ],
      ),
    );
  }
}
