// K-49: run on a device or emulator, e.g.
//   flutter test integration_test -d windows
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'courier_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('accept, pick up and deliver a request end to end', (
    tester,
  ) async {
    await runCourierFlow(tester);
  });
}
