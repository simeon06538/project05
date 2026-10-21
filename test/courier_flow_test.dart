import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/courier_flow.dart';

/// K-49: the same end-to-end flow as integration_test/, run as a normal
/// widget test so CI checks it without a device.
void main() {
  testWidgets('accept, pick up and deliver a request end to end', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await runCourierFlow(tester);
  });
}
