import 'package:flutter_test/flutter_test.dart';
import 'package:lipa_cart/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const LipaCartApp());

    // Verify app launches with splash screen elements
    expect(find.text('LC'), findsOneWidget);
  });
}
