import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet/app/router.dart';
import 'package:smart_wallet/app/routes.dart';
import 'package:smart_wallet/features/settings/data/app_info.dart';
import 'package:smart_wallet/features/settings/data/security_settings_repository.dart';
import 'package:smart_wallet/features/settings/view/help_about_screen.dart';
import 'package:smart_wallet/features/settings/view/security_settings_screen.dart';

/// Tall enough that the whole list is built, so every row can be found.
void _useTallViewport(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 2400);
  addTearDown(tester.view.reset);
}

Future<void> _pump(WidgetTester tester, {bool reduceMotion = false}) async {
  _useTallViewport(tester);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: const HelpAboutScreen(),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the brand card, build info and every link', (tester) async {
    await _pump(tester);

    expect(find.text('Help & About'), findsOneWidget);
    expect(find.text('Lexor Pocket'), findsOneWidget);
    expect(
      find.text('V${AppInfo.version} (BUILD ${AppInfo.build})'),
      findsOneWidget,
    );

    expect(find.text('SUPPORT & DOCUMENTATION'), findsOneWidget);
    expect(find.text('Help Center'), findsOneWidget);
    expect(find.text('Encrypted Live Desk'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('System Status'), findsOneWidget);

    expect(find.text('LEGAL & COMPLIANCE'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Privacy & Zero Log'), findsOneWidget);
    expect(find.text('Audits & Open Source'), findsOneWidget);

    expect(find.text('Love Lexor Pocket?'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('JOIN THE COMMUNITY'), findsOneWidget);
    expect(find.textContaining('All rights reserved'), findsOneWidget);
  });

  testWidgets('destinations without a launcher say so instead of doing nothing',
      (tester) async {
    await _pump(tester);

    final taps = <Finder, String>{
      find.text('Help Center'): 'Help Center',
      find.text('Encrypted Live Desk'): 'Live Desk',
      find.text('System Status'): 'System Status',
      find.text('Terms of Service'): 'Terms of Service',
      find.text('Privacy & Zero Log'): 'Privacy policy',
      find.text('Audits & Open Source'): 'Audits & Open Source',
      find.text('Review'): 'Store review',
    };
    for (final MapEntry(key: finder, value: name) in taps.entries) {
      await tester.tap(finder);
      await tester.pump();
      expect(find.text('$name is not available yet'), findsOneWidget);
    }
  });

  testWidgets('each community button is labelled and tappable', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);

    for (final network in ['X', 'Discord', 'Telegram', 'GitHub', 'Warpcast']) {
      await tester.tap(find.bySemanticsLabel(network));
      await tester.pump();
      expect(find.text('$network is not available yet'), findsOneWidget);
    }
    semantics.dispose();
  });

  testWidgets('the emblem stops animating when reduced motion is on',
      (tester) async {
    await _pump(tester, reduceMotion: true);
    // pumpAndSettle only returns if no animation is still scheduling frames.
    await tester.pumpAndSettle();
  });

  testWidgets('the emblem keeps pulsing otherwise without errors',
      (tester) async {
    await _pump(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Security Settings links to Help & About and back',
      (tester) async {
    _useTallViewport(tester);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SecuritySettingsScreen(),
        ),
        GoRoute(
          path: Routes.helpAbout,
          builder: (context, state) => const HelpAboutScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      RepositoryProvider<SecuritySettingsRepository>(
        create: (_) => InMemorySecuritySettingsRepository(),
        child: MaterialApp.router(
          routerConfig: router,
          // The emblem pulses forever otherwise, so nothing would settle.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('SUPPORT'), findsOneWidget);
    await tester.tap(find.text('Help & About'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byType(HelpAboutScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.byType(SecuritySettingsScreen), findsOneWidget);
  });

  test('the route is registered on the app router', () {
    final router = buildRouter();
    addTearDown(router.dispose);
    final paths = router.configuration.routes
        .whereType<GoRoute>()
        .map((r) => r.path)
        .toList();
    expect(paths, contains(Routes.helpAbout));
  });
}
