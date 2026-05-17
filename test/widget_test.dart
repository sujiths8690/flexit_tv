import 'package:flutter_test/flutter_test.dart';

import 'package:flexit/main.dart';

void main() {
  testWidgets('flexit app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const FlexitApp());

    expect(find.byType(FlexitApp), findsOneWidget);
  });
}
