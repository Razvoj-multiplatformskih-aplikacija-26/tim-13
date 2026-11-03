import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/dependencies.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 11, 2, 12));

  Future<AppDependencies> pumpApp(WidgetTester tester, {AppDependencies? dependencies}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final used = dependencies ?? AppDependencies.fake(clock: clock, latency: const Duration(milliseconds: 10));
    await tester.pumpWidget(AgroFlowApp(dependencies: used));
    return used;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  testWidgets('shows loading, then the data', (tester) async {
    await pumpApp(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await settle(tester);
    expect(find.text('Zaduženja'), findsWidgets);
    expect(find.text('Prskanje'), findsOneWidget);
  });

  testWidgets('shows the failure and recovers with retry', (tester) async {
    final dependencies = AppDependencies.fake(clock: clock, latency: const Duration(milliseconds: 10));
    dependencies.fakeOrders!.failingRequests = 1;
    await pumpApp(tester, dependencies: dependencies);
    await settle(tester);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);
    await tester.tap(find.text('Pokušaj ponovo'));
    await settle(tester);
    expect(find.text('Prskanje'), findsOneWidget);
  });

  testWidgets('shows the empty view', (tester) async {
    final dependencies = AppDependencies.fake(clock: clock, latency: const Duration(milliseconds: 10));
    dependencies.fakeOrders!.emptyResponses = 1;
    await pumpApp(tester, dependencies: dependencies);
    await settle(tester);
    expect(find.text('Nemate dodeljenih naloga.'), findsOneWidget);
  });

  testWidgets('swapping the repository needs no change in the screens', (tester) async {
    await pumpApp(tester, dependencies: AppDependencies.quietSeason());
    await settle(tester);
    expect(find.text('Nemate dodeljenih naloga.'), findsOneWidget);
  });

  testWidgets('starting an order blocked by stock shows the rule', (tester) async {
    await pumpApp(tester);
    await settle(tester);
    await tester.tap(find.text('Prskanje'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Započni rad'));
    await settle(tester);
    expect(find.textContaining('Nema dovoljno zaliha'), findsOneWidget);
  });

  testWidgets('the report form checks the parcel rule and sends the report', (tester) async {
    await pumpApp(tester);
    await settle(tester);
    await tester.tap(find.textContaining('Kod puta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unesi izveštaj'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('hectares')), '99');
    await tester.pump();
    expect(find.textContaining('ostalo još 15 ha'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('hectares')), '15');
    await tester.enterText(find.byKey(const Key('fuel')), '200');
    await tester.tap(find.text('Pošalji izveštaj'));
    await settle(tester);
    expect(find.text('Čeka potvrdu'), findsWidgets);
  });

  testWidgets('the profile shows the worker and a placeholder sign out', (tester) async {
    await pumpApp(tester);
    await settle(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Marko Jovanović'), findsOneWidget);
    expect(find.text('Aktivni nalozi'), findsOneWidget);
    await tester.tap(find.text('Odjavi se'));
    await tester.pump();
    expect(find.text('Odjava još nije povezana.'), findsOneWidget);
  });

  testWidgets('cancelling asks for confirmation', (tester) async {
    await pumpApp(tester);
    await settle(tester);
    await tester.tap(find.text('Prskanje'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otkaži nalog'));
    await tester.pumpAndSettle();
    expect(find.text('Otkazati nalog?'), findsOneWidget);
    await tester.tap(find.text('Otkaži nalog').last);
    await tester.pumpAndSettle();
    expect(find.text('Razlog je obavezan.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Kvar prskalice');
    await tester.tap(find.text('Otkaži nalog').last);
    await settle(tester);
    expect(find.text('Otkazan'), findsOneWidget);
  });
}
