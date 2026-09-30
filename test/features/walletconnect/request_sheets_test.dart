import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/app/theme/app_theme.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/walletconnect/data/in_memory_wallet_connect_repository.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_chain.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_dapp.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_request.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_session.dart';
import 'package:smart_wallet/features/walletconnect/data/models/wc_session_proposal.dart';
import 'package:smart_wallet/features/walletconnect/data/wallet_connect_repository.dart';
import 'package:smart_wallet/features/walletconnect/data/wc_demo_data.dart';
import 'package:smart_wallet/features/walletconnect/view/widgets/review_request_sheet.dart';
import 'package:smart_wallet/features/walletconnect/view/widgets/session_proposal_sheet.dart';
import 'package:smart_wallet/features/walletconnect/view/widgets/wc_request_host.dart';

import 'wallet_connect_screens_test.dart' show settleFor;
import 'wc_test_helpers.dart';

final _session = WcDemoData.sessions(testNow, '0x71C7656EC7ab88b098defB751B7401B5f6d8976F', 'Main Account').first;

WcRequest _demo(WcSimulatedRequestKind kind, {String id = 'r1'}) =>
    buildDemoRequest(kind: kind, id: id, session: _session, now: testNow);

Future<void> _pumpSheet(WidgetTester tester, Widget sheet) async {
  tester.view
    ..physicalSize = const Size(390 * 3, 844 * 3)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: sheet)),
    ),
  );
  await tester.pump();
}

void main() {
  group('review sheet routing', () {
    testWidgets('every request type gets its own sheet', (tester) async {
      final seen = <String>[];
      for (final (kind, title) in [
        (WcSimulatedRequestKind.message, 'Signature request'),
        (WcSimulatedRequestKind.typedData, 'Sign typed data'),
        (WcSimulatedRequestKind.swap, 'Confirm transaction'),
        (WcSimulatedRequestKind.unlimitedApproval, 'Approve spending'),
      ]) {
        await _pumpSheet(
          tester,
          buildRequestSheet(_demo(kind), onDecision: (_) {}),
        );
        expect(find.text(title), findsOneWidget, reason: '$kind');
        seen.add(title);
      }
      expect(seen, hasLength(4));
    });

    testWidgets('the source badge says where the request came from', (
      tester,
    ) async {
      await _pumpSheet(
        tester,
        buildRequestSheet(
          _demo(WcSimulatedRequestKind.message),
          onDecision: (_) {},
        ),
      );
      expect(find.text('UNISWAP VIA WALLETCONNECT'), findsOneWidget);
      expect(find.text('VERIFIED DOMAIN'), findsOneWidget);

      final browserRequest = WcPersonalSignRequest(
        id: 'b1',
        dapp: WcDemoData.uniswap,
        chain: WcChains.ethereum,
        signer: _session.accountAddress,
        receivedAt: testNow,
        origin: WcRequestOrigin.inAppBrowser,
        message: 'hi',
      );
      await _pumpSheet(
        tester,
        buildRequestSheet(browserRequest, onDecision: (_) {}),
      );
      expect(find.text('UNISWAP · IN-APP BROWSER'), findsOneWidget);
    });
  });

  group('SignMessageSheet', () {
    testWidgets('shows the exact message and reports the decision', (
      tester,
    ) async {
      final decisions = <WcRequestDecision>[];
      final request = _demo(WcSimulatedRequestKind.message);
      await _pumpSheet(
        tester,
        buildRequestSheet(request, onDecision: decisions.add),
      );

      expect(
        find.textContaining('wants you to sign in with your Ethereum account'),
        findsOneWidget,
      );
      await tester.tap(find.text('Sign'));
      await tester.tap(find.text('Reject'));
      expect(decisions.map((d) => d.approved), [true, false]);
    });

    testWidgets('warns when the message is not readable text', (tester) async {
      final request = WcPersonalSignRequest(
        id: 'r1',
        dapp: WcDemoData.uniswap,
        chain: WcChains.ethereum,
        signer: _session.accountAddress,
        receivedAt: testNow,
        message: '0xdeadbeef',
        messageIsReadable: false,
      );
      await _pumpSheet(tester, buildRequestSheet(request, onDecision: (_) {}));
      expect(find.text('Unreadable message'), findsOneWidget);
      expect(find.text('0xdeadbeef'), findsOneWidget);
    });

    testWidgets('busy disables both buttons', (tester) async {
      var taps = 0;
      await _pumpSheet(
        tester,
        buildRequestSheet(
          _demo(WcSimulatedRequestKind.message),
          busy: true,
          onDecision: (_) => taps++,
        ),
      );
      await tester.tap(find.text('Reject'), warnIfMissed: false);
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SignTypedDataSheet', () {
    testWidgets('a permit signature gets a prominent transfer warning', (
      tester,
    ) async {
      await _pumpSheet(
        tester,
        buildRequestSheet(
          _demo(WcSimulatedRequestKind.typedData),
          onDecision: (_) {},
        ),
      );
      expect(find.text('This can authorize token transfers'), findsOneWidget);
      expect(find.text('Sign anyway'), findsOneWidget);
      expect(find.text('PERMITSINGLE'), findsOneWidget);
      expect(find.text('Unlimited'), findsNothing);
      expect(find.text('1,000.00 USDC'), findsOneWidget);
    });

    testWidgets('an ordinary typed message shows a plain Sign button', (
      tester,
    ) async {
      final request = WcTypedDataRequest(
        id: 'r1',
        dapp: WcDemoData.uniswap,
        chain: WcChains.ethereum,
        signer: _session.accountAddress,
        receivedAt: testNow,
        primaryType: 'Mail',
        domain: const [WcTypedField('name', 'Ether Mail')],
        fields: const [WcTypedField('contents', 'Hello, Bob!')],
      );
      await _pumpSheet(tester, buildRequestSheet(request, onDecision: (_) {}));
      expect(find.text('Sign'), findsOneWidget);
      expect(find.text('This can authorize token transfers'), findsNothing);
      expect(find.text('Hello, Bob!'), findsOneWidget);
    });
  });

  group('TransactionRequestSheet', () {
    testWidgets('shows the simulated balance changes and fee', (tester) async {
      final decisions = <WcRequestDecision>[];
      await _pumpSheet(
        tester,
        buildRequestSheet(
          _demo(WcSimulatedRequestKind.swap),
          onDecision: decisions.add,
        ),
      );

      expect(find.text('-0.2500 ETH'), findsOneWidget);
      expect(find.text('+851.94 USDC'), findsOneWidget);
      expect(find.text('swapExactETHForTokens'), findsOneWidget);
      expect(find.textContaining('0.0021 ETH'), findsOneWidget);

      await tester.tap(find.text('Approve'));
      expect(decisions.single.approved, isTrue);
      expect(decisions.single.approvalCap, isNull);
    });

    testWidgets('says so when there is no simulation', (tester) async {
      final request = WcTransactionRequest(
        id: 'r1',
        dapp: WcDemoData.uniswap,
        chain: WcChains.ethereum,
        signer: _session.accountAddress,
        receivedAt: testNow,
        to: '0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD',
        valueDisplay: '1 ETH',
        networkFeeDisplay: 'Estimated when sent',
      );
      await _pumpSheet(tester, buildRequestSheet(request, onDecision: (_) {}));
      expect(find.text('No simulation available'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
    });

    group('unlimited approval', () {
      Future<List<WcRequestDecision>> pump(WidgetTester tester) async {
        final decisions = <WcRequestDecision>[];
        await _pumpSheet(
          tester,
          buildRequestSheet(
            _demo(WcSimulatedRequestKind.unlimitedApproval),
            onDecision: decisions.add,
          ),
        );
        return decisions;
      }

      testWidgets('warns and cannot be approved without a cap', (tester) async {
        final decisions = await pump(tester);

        expect(find.text('Unlimited token approval'), findsOneWidget);
        expect(find.text('Unlimited'), findsOneWidget);
        await tester.tap(find.text('Approve'), warnIfMissed: false);
        expect(decisions, isEmpty);
      });

      testWidgets('approves with the cap the user typed', (tester) async {
        final decisions = await pump(tester);

        await tester.enterText(find.byType(TextField), '500');
        await tester.pump();
        await tester.tap(find.text('Approve'));

        expect(decisions.single.approved, isTrue);
        expect(decisions.single.approvalCap, '500');
      });

      testWidgets('zero or junk is not a valid cap', (tester) async {
        final decisions = await pump(tester);

        for (final junk in ['0', '.', '0.0']) {
          await tester.enterText(find.byType(TextField), junk);
          await tester.pump();
          await tester.tap(find.text('Approve'), warnIfMissed: false);
        }
        expect(decisions, isEmpty);
      });

      testWidgets('keeping it unlimited is an explicit, labelled choice', (
        tester,
      ) async {
        final decisions = await pump(tester);

        await tester.tap(find.text('Keep unlimited (not recommended)'));
        await tester.pump();
        expect(find.text('Approve anyway'), findsOneWidget);
        await tester.tap(find.text('Approve anyway'));

        expect(decisions.single.approved, isTrue);
        expect(decisions.single.approvalCap, isNull);
      });
    });
  });

  group('SessionProposalSheet', () {
    WcSessionProposal proposal({WcVerification v = WcVerification.verified}) =>
        WcSessionProposal(
          id: 'p1',
          dapp: WcDemoData.aave.copyWith(verification: v),
          requiredChains: const [WcChains.ethereum],
          optionalChains: const [WcChains.polygon, WcChains.base],
          permissions: const [
            WcPermission.viewAccount,
            WcPermission.sendTransactions,
          ],
          expiresAt: testNow,
        );

    testWidgets('required networks are locked, optional ones toggle', (
      tester,
    ) async {
      List<WcChain>? approved;
      await _pumpSheet(
        tester,
        SessionProposalSheet(
          proposal: proposal(),
          onApprove: (chains) => approved = chains,
          onReject: () {},
        ),
      );

      expect(find.text('REQUIRED'), findsOneWidget);
      final switches = find.byType(Switch);
      expect(tester.widget<Switch>(switches.at(0)).onChanged, isNull);

      await tester.tap(switches.at(1)); // turn Polygon off
      await tester.pump();
      await tester.tap(find.text('Connect'));

      expect(approved, [WcChains.ethereum, WcChains.base]);
    });

    testWidgets('an unverified dApp gets a caution', (tester) async {
      await _pumpSheet(
        tester,
        SessionProposalSheet(
          proposal: proposal(v: WcVerification.unverified),
          onApprove: (_) {},
          onReject: () {},
        ),
      );
      expect(find.text("We couldn't verify this app"), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('a flagged dApp makes Reject the primary action', (
      tester,
    ) async {
      await _pumpSheet(
        tester,
        SessionProposalSheet(
          proposal: proposal(v: WcVerification.flagged),
          onApprove: (_) {},
          onReject: () {},
        ),
      );
      expect(find.text('Flagged as malicious'), findsWidgets);
      expect(find.text('Connect anyway'), findsOneWidget);
      final reject = tester.widget<Material>(
        find.ancestor(of: find.text('Reject'), matching: find.byType(Material)).first,
      );
      expect(reject.color, const Color(0xFFD4EE6B)); // accent, not neutral
    });
  });

  group('WcRequestHost', () {
    Future<(InMemoryWalletConnectRepository, GlobalKey<NavigatorState>)> pumpHost(
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final repo = buildRepository();
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        RepositoryProvider<WalletConnectRepository>.value(
          value: repo,
          child: MaterialApp(
            navigatorKey: key,
            theme: AppTheme.dark,
            builder: (context, child) =>
                WcRequestHost(navigatorKey: key, child: child!),
            home: const Scaffold(body: Text('home')),
          ),
        ),
      );
      await tester.pump();
      return (repo, key);
    }

    testWidgets('opens a sheet over whatever is on screen', (tester) async {
      final (repo, _) = await pumpHost(tester);

      await repo.simulateRequest(WcSimulatedRequestKind.message);
      await settleFor(tester, const Duration(milliseconds: 600));

      expect(find.text('Signature request'), findsOneWidget);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('Reject answers the request and closes the sheet', (
      tester,
    ) async {
      final (repo, _) = await pumpHost(tester);
      final request = repo.incomingRequests.first;

      await repo.simulateRequest(WcSimulatedRequestKind.message);
      await settleFor(tester, const Duration(milliseconds: 600));
      await tester.tap(find.text('Reject'));
      await settleFor(tester, const Duration(milliseconds: 600));

      expect(find.text('Signature request'), findsNothing);
      // Answered exactly once: a second answer is refused.
      final id = (await request).id;
      expect(
        (await repo.respond(id, const WcRequestDecision.reject())).isOk,
        isFalse,
      );
    });

    testWidgets('queued requests are reviewed one after another', (
      tester,
    ) async {
      final (repo, _) = await pumpHost(tester);

      await repo.simulateRequest(WcSimulatedRequestKind.message);
      await repo.simulateRequest(WcSimulatedRequestKind.swap);
      await settleFor(tester, const Duration(milliseconds: 600));
      expect(find.text('Signature request'), findsOneWidget);
      expect(find.text('+1 WAITING'), findsOneWidget);

      await tester.tap(find.text('Sign'));
      await settleFor(tester, const Duration(milliseconds: 600));
      expect(find.text('Signature request'), findsNothing);
      expect(find.text('Confirm transaction'), findsOneWidget);

      await tester.tap(find.text('Reject'));
      await settleFor(tester, const Duration(milliseconds: 600));
      expect(find.text('Confirm transaction'), findsNothing);
    });

    testWidgets('swiping the sheet away rejects the request', (tester) async {
      final (repo, _) = await pumpHost(tester);
      final first = repo.incomingRequests.first;
      final barriersBefore = find.byType(ModalBarrier).evaluate().length;

      await repo.simulateRequest(WcSimulatedRequestKind.message);
      await settleFor(tester, const Duration(milliseconds: 600));
      await tester.tapAt(const Offset(195, 40)); // modal barrier
      await settleFor(tester, const Duration(milliseconds: 600));

      // No leftover scrim (regression: a second, empty sheet stayed open).
      expect(find.byType(ModalBarrier).evaluate().length, barriersBefore);

      expect(find.text('Signature request'), findsNothing);
      expect(
        (await repo.respond((await first).id, const WcRequestDecision.reject()))
            .isOk,
        isFalse, // already answered by the dismissal
      );
    });
  });
}
