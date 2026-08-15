import 'package:olcerim/core/constants/app_constants.dart';

enum AppLayoutClass { compact, medium, expanded }

abstract final class AppBreakpoints {
  static AppLayoutClass ofWidth(double width) {
    if (width < AppConstants.compactBreakpoint) {
      return AppLayoutClass.compact;
    }
    if (width < AppConstants.expandedBreakpoint) {
      return AppLayoutClass.medium;
    }
    return AppLayoutClass.expanded;
  }
}
