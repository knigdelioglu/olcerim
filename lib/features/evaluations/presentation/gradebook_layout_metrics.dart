import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Shared geometry for the wide-screen gradebook.
///
/// Frozen student cells and score rows must use the same height. The metrics
/// grow with the system text scaler instead of clipping larger accessibility
/// text into the historical 52/64 dp fixed heights.
abstract final class GradebookLayoutMetrics {
  static const double minimumTouchTarget = 48;
  static const double baseHeaderHeight = 52;
  static const double baseRowHeight = 64;

  static double headerHeight(TextScaler textScaler) {
    final scaledLabelLine = textScaler.scale(14) * 1.45;
    return math.max(baseHeaderHeight, scaledLabelLine + 24);
  }

  static double rowHeight(TextScaler textScaler) {
    final scaledPrimaryLine = textScaler.scale(14) * 1.45;
    final scaledSecondaryLine = textScaler.scale(12) * 1.35;
    return math.max(
      baseRowHeight,
      scaledPrimaryLine + scaledSecondaryLine + 20,
    );
  }
}
