import 'package:flutter_test/flutter_test.dart';
import 'package:educinema_lms/main.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const EduCinemaApp());
    expect(find.text('EduCinema'), findsOneWidget);
  });
}
