import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/app/layout/app_breakpoints.dart';

void main() {
  test('360 dp compact layouttır', () => expect(AppBreakpoints.ofWidth(360), AppLayoutClass.compact));
  test('768 dp medium layouttır', () => expect(AppBreakpoints.ofWidth(768), AppLayoutClass.medium));
  test('1440 dp expanded layouttır', () => expect(AppBreakpoints.ofWidth(1440), AppLayoutClass.expanded));
  test('breakpoint sınırları deterministiktir', () { expect(AppBreakpoints.ofWidth(599), AppLayoutClass.compact); expect(AppBreakpoints.ofWidth(600), AppLayoutClass.medium); expect(AppBreakpoints.ofWidth(1024), AppLayoutClass.expanded); });
}
