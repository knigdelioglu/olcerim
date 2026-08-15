import 'package:flutter/material.dart';
import 'package:olcerim/app/layout/app_breakpoints.dart';

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    required this.compact,
    required this.medium,
    required this.expanded,
    super.key,
  });

  final Widget compact;
  final Widget medium;
  final Widget expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return switch (AppBreakpoints.ofWidth(constraints.maxWidth)) {
          AppLayoutClass.compact => compact,
          AppLayoutClass.medium => medium,
          AppLayoutClass.expanded => expanded,
        };
      },
    );
  }
}
