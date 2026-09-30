import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wallet/app/theme/app_theme.dart';
import 'package:smart_wallet/features/walletconnect/view/qr_scanner_screen.dart';

import 'wc_test_helpers.dart';

void main() {
  late ValueChanged<String> scan;
  String? result;
  var resolved = false;

  Future<void> pump(WidgetTester tester) async {
    result = null;
    resolved = false;
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (c, s) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await c.push<String>('/scan');
              resolved = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(
        path: '/scan',
        builder: (c, s) => QrScannerScreen(
          scannerBuilder: (context, onRaw) {
            scan = onRaw;
            return const SizedBox.expand();
          },
        ),
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.dark, routerConfig: router));
    await tester.tap(find.text('open'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('a valid pairing QR pops with the link, once', (tester) async {
    await pump(tester);
    final link = validPairingLink();
    scan(link);
    scan(validPairingLink(seed: 5)); // second detection is ignored
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(resolved, isTrue);
    expect(result, link);
  });

  testWidgets('a foreign QR shows a hint and keeps scanning', (tester) async {
    await pump(tester);
    scan('https://example.com');
    await tester.pump();
    expect(find.textContaining("isn't a WalletConnect link"), findsOneWidget);
    expect(resolved, isFalse);

    scan(validPairingLink());
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(resolved, isTrue);
  });
}
