import 'package:flutter_test/flutter_test.dart';

import 'package:menuboard_tv/main.dart';

void main() {
  testWidgets('MenuBoard app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MenuBoardApp());

    expect(find.byType(MenuBoardApp), findsOneWidget);
  });
}
