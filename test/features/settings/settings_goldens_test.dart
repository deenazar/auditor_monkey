@Tags(<String>['golden'])
library;

import 'package:auditor_monkey/features/settings/presentation/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

void main() {
  testWidgets('golden: settings', (WidgetTester tester) async {
    await pumpGolden(tester, const SettingsScreen(), 'settings');
  });
}
