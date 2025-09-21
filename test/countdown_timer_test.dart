import 'package:flutter_test/flutter_test.dart';
import 'package:mansa_white/widgets/countdown_timer.dart';

void main() {
  group('CountdownTimer Widget Tests', () {
    testWidgets('should display countdown for future date',
        (WidgetTester tester) async {
      final futureDate =
          DateTime.now().add(const Duration(days: 5, hours: 3, minutes: 30));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownTimer(expiryDate: futureDate),
          ),
        ),
      );

      // Wait for the timer to initialize
      await tester.pump(const Duration(seconds: 1));

      // Check that the countdown is displayed
      expect(find.textContaining('معاد التجديد'), findsOneWidget);
      expect(find.textContaining('يوم'), findsOneWidget);
    });

    testWidgets('should display expired message for past date',
        (WidgetTester tester) async {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownTimer(expiryDate: pastDate),
          ),
        ),
      );

      // Wait for the timer to initialize
      await tester.pump(const Duration(seconds: 1));

      // Check that the expired message is displayed
      expect(find.text('انتهت الصلاحية'), findsOneWidget);
    });
  });
}
