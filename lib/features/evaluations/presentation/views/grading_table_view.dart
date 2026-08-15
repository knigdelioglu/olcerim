import 'package:flutter/material.dart';

class GradingTableView extends StatelessWidget {
  const GradingTableView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Değerlendirme', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Öğrenci × rubrik kriteri puanlama tablosu bu feature içinde geliştirilecek.'),
        ],
      ),
    );
  }
}
