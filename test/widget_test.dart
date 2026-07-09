import 'package:flutter_test/flutter_test.dart';

import 'package:autocare_app/main.dart';

void main() {
  testWidgets('Login Screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app name 'AutoCare+' exists on the screen.
    expect(find.text('AutoCare+'), findsWidgets);

    // Verify that the login form fields / labels are present.
    expect(find.text('MASUK'), findsWidgets);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Email atau Username'), findsOneWidget);

    // Verify that the register toggle link is present.
    expect(find.text('Daftar di sini'), findsOneWidget);
  });
}
