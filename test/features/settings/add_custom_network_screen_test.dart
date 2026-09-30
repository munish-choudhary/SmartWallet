import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet/app/routes.dart';
import 'package:smart_wallet/core/network/rpc_probe_service.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/settings/data/custom_network_repository.dart';
import 'package:smart_wallet/features/settings/view/add_custom_network_screen.dart';
import 'package:smart_wallet/features/settings/view_model/add_custom_network_cubit.dart';

import 'fake_custom_network_repository.dart';

const _home = '/home';

Future<GoRouter> _pumpScreen(
  WidgetTester tester,
  FakeCustomNetworkRepository repo,
) async {
  // Tall enough that the whole form is built (ListView builds lazily).
  tester.view.physicalSize = const Size(390, 1900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: _home,
    routes: [
      // A Scaffold, like the real Portfolio route: snackbars need one.
      GoRoute(
        path: _home,
        builder: (_, __) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: Routes.addCustomNetwork,
        builder: (_, __) => BlocProvider(
          create: (_) => AddCustomNetworkCubit(repository: repo),
          child: const AddCustomNetworkScreen(),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    RepositoryProvider<CustomNetworkRepository>.value(
      value: repo,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  unawaited(router.push(Routes.addCustomNetwork));
  await tester.pumpAndSettle();
  return router;
}

Finder _field(int index) => find.byType(TextField).at(index);

// Field order on screen.
const _name = 0, _rpc = 1, _chainId = 2, _symbol = 3, _explorer = 4;

Future<void> _tapSave(WidgetTester tester) async {
  await tester.tap(find.text('Verify & Save Network'));
  await tester.pumpAndSettle();
}

Future<void> _fillValid(WidgetTester tester) async {
  await tester.enterText(_field(_name), 'Polygon Relay');
  await tester.enterText(_field(_rpc), 'https://rpc.example.com');
  await tester.enterText(_field(_chainId), '137');
  await tester.enterText(_field(_symbol), 'pol');
  await tester.pump();
}

void main() {
  late FakeCustomNetworkRepository repo;

  setUp(() => repo = FakeCustomNetworkRepository());

  testWidgets('shows the form, presets and the security warning',
      (tester) async {
    await _pumpScreen(tester, repo);

    expect(find.text('Add Custom Network'), findsOneWidget);
    // The chip row is a lazy horizontal list: scroll to reach the last ones.
    final chips = find.byType(Scrollable).at(1);
    for (final label in ['Ethereum', 'Base', 'Arbitrum', 'Polygon', 'BNB Chain']) {
      await tester.scrollUntilVisible(
        find.text(label),
        100,
        scrollable: chips,
      );
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Network Name'), findsOneWidget);
    expect(find.text('RPC URL'), findsOneWidget);
    expect(find.text('Chain ID'), findsOneWidget);
    expect(find.text('Symbol'), findsOneWidget);
    expect(find.text('Block Explorer'), findsOneWidget);
    expect(find.text('MALICIOUS RPC RISK'), findsOneWidget);
    expect(find.text('Not tested'), findsOneWidget);
    expect(repo.probed, isEmpty, reason: 'nothing is sent until asked');
  });

  testWidgets('a preset fills the form and shows the measured latency',
      (tester) async {
    repo.probeResult = const Result.ok(
      RpcProbe(latency: Duration(milliseconds: 42), chainId: 8453),
    );
    await _pumpScreen(tester, repo);

    await tester.tap(find.text('Base'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(_field(_name)).controller!.text, 'Base');
    expect(
      tester.widget<TextField>(_field(_rpc)).controller!.text,
      'https://mainnet.base.org',
    );
    expect(tester.widget<TextField>(_field(_chainId)).controller!.text, '8453');
    expect(tester.widget<TextField>(_field(_symbol)).controller!.text, 'ETH');
    expect(
      tester.widget<TextField>(_field(_explorer)).controller!.text,
      'https://basescan.org',
    );
    expect(find.text('42ms'), findsOneWidget);
    expect(find.text('Fast'), findsOneWidget);
    expect(find.text('Matches RPC'), findsOneWidget);
    expect(find.text('Preset'), findsOneWidget);
    expect(repo.added, isEmpty, reason: 'a preset only fills the form');

    await tester.enterText(_field(_name), 'My Base');
    await tester.pump();
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets('saving an empty form shows what is missing and sends nothing',
      (tester) async {
    await _pumpScreen(tester, repo);
    await _tapSave(tester);

    expect(find.text('This field is required'), findsNWidgets(4));
    expect(repo.probed, isEmpty);
    expect(repo.added, isEmpty);
  });

  testWidgets('http RPC URLs are refused with an explanation', (tester) async {
    await _pumpScreen(tester, repo);
    await _fillValid(tester);
    await tester.enterText(_field(_rpc), 'http://rpc.example.com');
    await tester.pump();
    await _tapSave(tester);

    expect(find.textContaining('Use https://'), findsOneWidget);
    // (The https URL typed first was probed when focus left the field.)
    expect(repo.probed.where((u) => u.scheme == 'http'), isEmpty);
    expect(repo.added, isEmpty);
  });

  testWidgets('a valid form is verified, saved, and the screen closes',
      (tester) async {
    repo.probeResult = const Result.ok(
      RpcProbe(latency: Duration(milliseconds: 80), chainId: 137),
    );
    await _pumpScreen(tester, repo);
    await _fillValid(tester);
    await _tapSave(tester);

    expect(repo.added.single.name, 'Polygon Relay');
    expect(repo.added.single.chainId, 137);
    expect(repo.added.single.currencySymbol, 'POL');
    expect(find.byType(AddCustomNetworkScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
    expect(find.text('Polygon Relay added'), findsOneWidget);
  });

  testWidgets('a chain ID the RPC does not serve is not saved',
      (tester) async {
    repo.probeResult = const Result.ok(
      RpcProbe(latency: Duration(milliseconds: 80), chainId: 1),
    );
    await _pumpScreen(tester, repo);
    await _fillValid(tester);
    await _tapSave(tester);

    expect(
      find.text('The RPC reports chain ID 1, not this one'),
      findsWidgets,
    );
    expect(repo.added, isEmpty);
    expect(find.byType(AddCustomNetworkScreen), findsOneWidget);
  });

  testWidgets('an unreachable endpoint is reported and nothing is saved',
      (tester) async {
    repo.probeResult =
        const Result.err(AppFailure.network('Endpoint unreachable'));
    await _pumpScreen(tester, repo);
    await _fillValid(tester);
    await _tapSave(tester);

    expect(find.textContaining("Couldn't reach this RPC endpoint"), findsOneWidget);
    expect(find.text('Unreachable'), findsOneWidget);
    expect(repo.added, isEmpty);
  });

  testWidgets('a duplicate is reported and the form stays open',
      (tester) async {
    repo
      ..probeResult = const Result.ok(
        RpcProbe(latency: Duration(milliseconds: 80), chainId: 137),
      )
      ..addResult = const Result.err(AppFailure.duplicateNetwork());
    await _pumpScreen(tester, repo);
    await _fillValid(tester);
    await _tapSave(tester);

    expect(find.textContaining('already saved'), findsOneWidget);
    expect(find.text('Verify & Save Network'), findsOneWidget);
  });

  testWidgets('leaving the RPC field tests it once; refresh tests again',
      (tester) async {
    await _pumpScreen(tester, repo);
    await tester.enterText(_field(_rpc), 'https://rpc.example.com');
    await tester.pump();
    expect(repo.probed, isEmpty, reason: 'typing alone sends nothing');

    // Tapping the next field moves focus off the RPC field.
    await tester.tap(_field(_chainId));
    await tester.pumpAndSettle();
    expect(repo.probed, hasLength(1));

    await tester.tap(_field(_symbol));
    await tester.tap(_field(_rpc));
    await tester.tap(_field(_chainId));
    await tester.pumpAndSettle();
    expect(repo.probed, hasLength(1), reason: 'already tested');

    await tester.tap(find.byTooltip('Test connection'));
    await tester.pumpAndSettle();
    expect(repo.probed, hasLength(2));
  });

  testWidgets('cancel closes without saving', (tester) async {
    await _pumpScreen(tester, repo);
    await _fillValid(tester);
    await tester.tap(find.text('Cancel & Discard'));
    await tester.pumpAndSettle();

    expect(repo.added, isEmpty);
    expect(find.byType(AddCustomNetworkScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('the symbol field drops odd characters; chain ID takes digits only',
      (tester) async {
    await _pumpScreen(tester, repo);
    await tester.enterText(_field(_chainId), '1a2-3');
    await tester.enterText(_field(_symbol), 'e t-h!');
    await tester.pump();

    expect(tester.widget<TextField>(_field(_chainId)).controller!.text, '123');
    expect(tester.widget<TextField>(_field(_symbol)).controller!.text, 'eth');
  });
}
