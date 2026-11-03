import 'package:backoffice/app.dart';
import 'package:backoffice/dependencies.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 11, 2, 12));

  Future<BackofficeDependencies> pumpApp(
    WidgetTester tester, {
    Size size = const Size(1280, 720),
    BackofficeDependencies? dependencies,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final used = dependencies ?? BackofficeDependencies.fake(clock: clock, latency: const Duration(milliseconds: 10));
    await tester.pumpWidget(BackofficeApp(dependencies: used));
    return used;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key, {int times = 1}) async {
    for (var i = 0; i < times; i++) {
      await tester.sendKeyEvent(key);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('shows the failure, then recovers with retry', (tester) async {
    final dependencies = BackofficeDependencies.fake(clock: clock, latency: const Duration(milliseconds: 10));
    dependencies.fakeOrders!.failingRequests = 1;
    await pumpApp(tester, dependencies: dependencies);
    await settle(tester);
    await tester.tap(find.text('Pokušaj ponovo'));
    await settle(tester);
    expect(find.text('Mašina'), findsOneWidget);
  });

  testWidgets('shows the empty view', (tester) async {
    final dependencies = BackofficeDependencies.fake(clock: clock, latency: const Duration(milliseconds: 10));
    dependencies.fakeOrders!.emptyResponses = 1;
    await pumpApp(tester, dependencies: dependencies);
    await settle(tester);
    expect(find.text('Nema radnih naloga.'), findsOneWidget);
  });

  testWidgets('works from the keyboard alone', (tester) async {
    await pumpApp(tester);
    await settle(tester);

    await press(tester, LogicalKeyboardKey.arrowDown, times: 2);
    await press(tester, LogicalKeyboardKey.enter);
    expect(find.text('Zatvori detalj'), findsNothing);
    expect(find.byTooltip('Zatvori (Esc)'), findsOneWidget);

    await press(tester, LogicalKeyboardKey.escape);
    expect(find.byTooltip('Zatvori (Esc)'), findsNothing);

    await press(tester, LogicalKeyboardKey.keyN);
    expect(find.text('Novi radni nalog'), findsOneWidget);
  });

  testWidgets('narrowing the window swaps the table for a list and keeps the selection', (tester) async {
    await pumpApp(tester);
    await settle(tester);
    expect(find.text('Mašina'), findsOneWidget);

    await press(tester, LogicalKeyboardKey.arrowDown, times: 3);
    await press(tester, LogicalKeyboardKey.enter);

    tester.view.physicalSize = const Size(600, 800);
    await tester.pumpAndSettle();

    expect(find.text('Termin'), findsOneWidget);
    expect(find.byTooltip('Zatvori (Esc)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('approving a report changes the stage', (tester) async {
    await pumpApp(tester);
    await settle(tester);
    await tester.tap(find.text('Čeka potvrdu').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bara'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await settle(tester);
    expect(find.text('Nalog je odobren.'), findsOneWidget);
  });

  testWidgets('the profile shows the owner and a placeholder sign out', (tester) async {
    await pumpApp(tester);
    await settle(tester);
    await tester.tap(find.byTooltip('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Stevan Ilić'), findsOneWidget);
    expect(find.text('Radni nalozi'), findsOneWidget);
    await tester.tap(find.text('Odjavi se'));
    await tester.pump();
    expect(find.text('Odjava još nije povezana.'), findsOneWidget);
  });

  testWidgets('a new order is refused when the worker is busy', (tester) async {
    await pumpApp(tester);
    await settle(tester);
    await tester.tap(find.byTooltip('Novi nalog (N)'));
    await tester.pumpAndSettle();
    expect(find.text('Sačuvaj'), findsOneWidget);
    expect(find.text('Radnik u tom terminu već ima nalog.'), findsOneWidget);
  });
}
