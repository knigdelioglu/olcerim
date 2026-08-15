import 'package:flutter/material.dart';

class RubricEditorView extends StatelessWidget {
  const RubricEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rubrikler', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Kriterleri, azami puanları ve sıralamayı burada yönetin.'),
        ],
      ),
    );
  }
}
