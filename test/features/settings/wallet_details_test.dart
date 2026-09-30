import 'dart:math';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/features/portfolio/data/models/token_asset.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_wallet/app/app.dart';
import 'package:smart_wallet/app/routes.dart';
import 'package:smart_wallet/app/theme/app_durations.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/core/vault/fake_vault.dart';
import 'package:smart_wallet/core/vault/pin.dart';
import 'package:smart_wallet/core/vault/vault.dart';
import 'package:smart_wallet/features/onboarding/data/bip39_wordlist.dart';
import 'package:smart_wallet/features/portfolio/data/models/portfolio_snapshot.dart';
import 'package:smart_wallet/features/portfolio/data/portfolio_repository.dart';
import 'package:smart_wallet/features/settings/data/wallet_name.dart';
import 'package:smart_wallet/features/settings/data/wallet_name_store.dart';
import 'package:smart_wallet/features/settings/data/wallet_profile.dart';
import 'package:smart_wallet/features/settings/data/wallet_profile_repository.dart';
import 'package:smart_wallet/features/settings/view/rename_wallet_screen.dart';
import 'package:smart_wallet/features/settings/view/wallet_details_screen.dart';
import 'package:smart_wallet/features/settings/view/widgets/settings_palette.dart';
import 'package:smart_wallet/features/settings/view_model/rename_wallet_cubit.dart';
import 'package:smart_wallet/features/settings/view_model/rename_wallet_state.dart';
import 'package:smart_wallet/features/settings/view_model/wallet_details_cubit.dart';
import 'package:smart_wallet/features/settings/view_model/wallet_details_state.dart';

const _address = '0x71C8a1f0e2D3b4c5A6B7d8E9f0a1B2c3D4e5b94F9b';

/// Programmable stand-in for [WalletProfileRepository].
class _FakeProfiles implements WalletProfileRepository {
  _FakeProfiles({
    this.derivationPath = "m/44'/60'/0'/0/0",
    this.loadFailure,
    this.renameFailure,
  });

  String name = "Alex's Primary Vault";
  final String? derivationPath;
  AppFailure? loadFailure;
  AppFailure? renameFailure;
  final renamed = <String>[];

  @override
  Future<Result<WalletProfile>> load() async {
    final failure = loadFailure;
    if (failure != null) return Result.err(failure);
    return Result.ok(
      WalletProfile(
        walletId: 'wallet-1',
        name: name,
        address: _address,
        derivationPath: derivationPath,
      ),
    );
  }

  @override
  Future<Result<WalletRoster>> loadAll() async {
    final profile = (await load()).valueOrNull;
    if (profile == null) return Result.err(loadFailure!);
    return Result.ok(
      WalletRoster(wallets: [profile], activeId: profile.walletId),
    );
  }

  @override
  Future<Result<void>> switchTo(String walletId) async =>
      const Result.ok(null);

  @override
  Future<Result<void>> rename(String newName) async {
    final failure = renameFailure;
    if (failure != null) return Result.err(failure);
    name = newName;
    renamed.add(newName);
    return const Result.ok(null);
  }
}

class _FailingPortfolio implements PortfolioRepository {
  @override
  Future<Result<PortfolioSnapshot>> getSnapshot() async =>
      const Result.err(AppFailure.network('offline'));
  @override
  Stream<Result<PortfolioSnapshot>> watchSnapshot() => const Stream.empty();
  @override
  Future<Result<PortfolioSnapshot>> refresh() => getSnapshot();
  @override
  Future<Result<void>> toggleFavorite(String tokenId) async =>
      const Result.ok(null);
  @override
  Future<Result<void>> toggleHidden(String tokenId) async =>
      const Result.ok(null);
  @override
  Future<Result<void>> addCustomToken(TokenAsset token) async =>
      const Result.ok(null);
}

class _ThrowingNameStore implements WalletNameStore {
  @override
  Future<String?> read(WalletId walletId) async => throw StateError('boom');
  @override
  Future<void> write(WalletId walletId, String name) async =>
      throw StateError('boom');
  @override
  Future<void> delete(WalletId walletId) async {}
}

Future<FakeVault> _vaultWithWallet() async {
  final vault = FakeVault(
    wordlist: await Bip39Wordlist.load(),
    random: Random(1),
  );
  await vault.importPrivateKey(
    Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
    CoinType.ethereum,
    pin: Pin('246810'),
  );
  return vault;
}

void main() {
  group('WalletName', () {
    test('trims surrounding whitespace', () {
      expect(WalletName.normalize('  Main Portfolio \n'), 'Main Portfolio');
    });

    test('accepts 1..32 characters and rejects the rest', () {
      expect(WalletName.isValid(''), isFalse);
      expect(WalletName.isValid('   '), isFalse);
      expect(WalletName.isValid('a'), isTrue);
      expect(WalletName.isValid('a' * 32), isTrue);
      expect(WalletName.isValid('a' * 33), isFalse);
    });

    test('counts an emoji as one character', () {
      expect(WalletName.lengthOf('😀' * 32), 32);
      expect(WalletName.isValid('😀' * 32), isTrue);
      expect(WalletName.isValid('😀' * 33), isFalse);
    });

    test('every preset suggestion is itself a valid name', () {
      for (final name in WalletName.suggestions) {
        expect(WalletName.isValid(name), isTrue, reason: name);
      }
    });
  });

  group('WalletProfile', () {
    test('shortens the address to first 6 and last 6', () {
      const profile =
          WalletProfile(walletId: 'w', name: 'n', address: _address);
      expect(profile.shortAddress, '0x71C8...b94F9b');
    });

    test('leaves an already-short address alone', () {
      expect(shortenAddress('0xABC'), '0xABC');
    });

    test('builds explorer links from the full address', () {
      const profile =
          WalletProfile(walletId: 'w', name: 'n', address: _address);
      expect(profile.etherscanUrl, 'https://etherscan.io/address/$_address');
      expect(profile.blockscanUrl, 'https://blockscan.com/address/$_address');
    });
  });

  group('VaultWalletProfileRepository', () {
    test('loads the default name, then the renamed one', () async {
      final repository = VaultWalletProfileRepository(
        vault: await _vaultWithWallet(),
        names: InMemoryWalletNameStore(),
      );

      final first = (await repository.load()).valueOrNull!;
      expect(first.name, WalletName.fallback);
      expect(first.address, startsWith('0x'));

      expect((await repository.rename('  Trading Stash  ')).isOk, isTrue);
      expect((await repository.load()).valueOrNull!.name, 'Trading Stash');
    });

    test('rejects an empty or over-long name without storing it', () async {
      final store = InMemoryWalletNameStore();
      final vault = await _vaultWithWallet();
      final repository = VaultWalletProfileRepository(vault: vault, names: store);

      expect((await repository.rename('   ')).isOk, isFalse);
      expect((await repository.rename('a' * 33)).isOk, isFalse);
      final walletId = (await vault.activeWalletId()).valueOrNull!;
      expect(await store.read(walletId), isNull);
    });

    test('fails with walletNotFound when there is no wallet', () async {
      final repository = VaultWalletProfileRepository(
        vault: FakeVault(wordlist: await Bip39Wordlist.load()),
        names: InMemoryWalletNameStore(),
      );
      expect((await repository.load()).failureOrNull,
          isA<WalletNotFoundFailure>());
      expect((await repository.rename('Fine')).failureOrNull,
          isA<WalletNotFoundFailure>());
    });

    test('a store failure never leaks through as an exception', () async {
      final repository = VaultWalletProfileRepository(
        vault: await _vaultWithWallet(),
        names: _ThrowingNameStore(),
      );
      // Unreadable name → still loads, with the default.
      expect((await repository.load()).valueOrNull!.name, WalletName.fallback);
      // Unwritable name → an Err, not a throw.
      expect((await repository.rename('Fine')).failureOrNull,
          isA<UnknownFailure>());
    });
  });

  group('WalletDetailsCubit', () {
    late PortfolioSnapshot snapshot;
    setUp(() async {
      snapshot =
          (await InMemoryPortfolioRepository().getSnapshot()).valueOrNull!;
    });

    const profile = WalletProfile(
      walletId: 'wallet-1',
      name: "Alex's Primary Vault",
      address: _address,
      derivationPath: "m/44'/60'/0'/0/0",
    );

    blocTest<WalletDetailsCubit, WalletDetailsState>(
      'loads the profile together with the portfolio',
      build: () => WalletDetailsCubit(
        profiles: _FakeProfiles(),
        portfolio: InMemoryPortfolioRepository(),
      ),
      wait: const Duration(milliseconds: 10),
      expect: () => [WalletDetailsState.loaded(profile, portfolio: snapshot)],
    );

    blocTest<WalletDetailsCubit, WalletDetailsState>(
      'still loads when only the balance is unavailable',
      build: () => WalletDetailsCubit(
        profiles: _FakeProfiles(),
        portfolio: _FailingPortfolio(),
      ),
      wait: const Duration(milliseconds: 10),
      expect: () => [const WalletDetailsState.loaded(profile)],
    );

    blocTest<WalletDetailsCubit, WalletDetailsState>(
      'fails when the profile cannot be read',
      build: () => WalletDetailsCubit(
        profiles: _FakeProfiles(loadFailure: const AppFailure.vaultLocked()),
        portfolio: InMemoryPortfolioRepository(),
      ),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        const WalletDetailsState.failure(AppFailure.vaultLocked()),
      ],
    );

    blocTest<WalletDetailsCubit, WalletDetailsState>(
      'refresh swaps in the new name without showing the spinner',
      build: () => WalletDetailsCubit(
        profiles: _FakeProfiles(),
        portfolio: InMemoryPortfolioRepository(),
      ),
      act: (cubit) async {
        await pumpEventQueue();
        await cubit.refresh();
      },
      // The second, identical `loaded` is de-duplicated by Bloc; the point is
      // that no `loading` appears between them.
      expect: () => [WalletDetailsState.loaded(profile, portfolio: snapshot)],
    );

    test('does not emit after being closed mid-load', () async {
      final cubit = WalletDetailsCubit(
        profiles: _FakeProfiles(),
        portfolio: InMemoryPortfolioRepository(),
      );
      await cubit.close();
      await pumpEventQueue(); // would throw a StateError if it still emitted
    });
  });

  group('RenameWalletCubit', () {
    const ready = RenameWalletReady(
      currentName: "Alex's Primary Vault",
      shortAddress: '0x71C8...b94F9b',
      draft: "Alex's Primary Vault",
    );

    blocTest<RenameWalletCubit, RenameWalletState>(
      'loads the current name as the draft',
      build: () => RenameWalletCubit(repository: _FakeProfiles()),
      wait: const Duration(milliseconds: 10),
      expect: () => [ready],
    );

    blocTest<RenameWalletCubit, RenameWalletState>(
      'fails when the wallet cannot be read',
      build: () => RenameWalletCubit(
        repository:
            _FakeProfiles(loadFailure: const AppFailure.walletNotFound()),
      ),
      wait: const Duration(milliseconds: 10),
      expect: () => [
        const RenameWalletState.failure(AppFailure.walletNotFound()),
      ],
    );

    blocTest<RenameWalletCubit, RenameWalletState>(
      'saves the trimmed draft and reports it as saved',
      build: () => RenameWalletCubit(repository: _FakeProfiles()),
      act: (cubit) async {
        await pumpEventQueue();
        cubit.draftChanged('  Trading Stash ');
        await cubit.save();
      },
      expect: () => [
        ready,
        ready.copyWith(draft: '  Trading Stash '),
        ready.copyWith(draft: '  Trading Stash ', saving: true),
        const RenameWalletState.saved('Trading Stash'),
      ],
    );

    blocTest<RenameWalletCubit, RenameWalletState>(
      'does not save an unchanged, empty or over-long name',
      build: () => RenameWalletCubit(repository: _FakeProfiles()),
      act: (cubit) async {
        await pumpEventQueue();
        await cubit.save(); // unchanged
        cubit.draftChanged('   ');
        await cubit.save(); // empty after trim
        cubit.draftChanged('a' * 33);
        await cubit.save(); // too long
      },
      expect: () => [
        ready,
        ready.copyWith(draft: '   '),
        ready.copyWith(draft: 'a' * 33),
      ],
    );

    blocTest<RenameWalletCubit, RenameWalletState>(
      'treats a name that only differs by whitespace as unchanged',
      build: () => RenameWalletCubit(repository: _FakeProfiles()),
      act: (cubit) async {
        await pumpEventQueue();
        cubit.draftChanged("  Alex's Primary Vault ");
        await cubit.save();
      },
      expect: () => [
        ready,
        ready.copyWith(draft: "  Alex's Primary Vault "),
      ],
    );

    blocTest<RenameWalletCubit, RenameWalletState>(
      'keeps the draft and reports a failed save, clearing it on the next edit',
      build: () => RenameWalletCubit(
        repository: _FakeProfiles(
          renameFailure: const AppFailure.unknown('nope'),
        ),
      ),
      act: (cubit) async {
        await pumpEventQueue();
        cubit.draftChanged('Trading Stash');
        await cubit.save();
        cubit.draftChanged('Trading Stash 2');
      },
      expect: () => [
        ready,
        ready.copyWith(draft: 'Trading Stash'),
        ready.copyWith(draft: 'Trading Stash', saving: true),
        ready.copyWith(
          draft: 'Trading Stash',
          saveFailure: const AppFailure.unknown('nope'),
        ),
        ready.copyWith(draft: 'Trading Stash 2'),
      ],
    );
  });

  group('screens', () {
    late _FakeProfiles profiles;

    setUp(() => profiles = _FakeProfiles());

    /// The real routes for these two screens (plus stubs for the rows that
    /// navigate elsewhere), so `context.push` / `pop(result)` behave as in
    /// the app.
    Widget app({PortfolioRepository? portfolio}) {
      final router = GoRouter(
        initialLocation: Routes.walletDetails,
        routes: [
          GoRoute(
            path: Routes.walletDetails,
            builder: (_, _) => BlocProvider(
              create: (_) => WalletDetailsCubit(
                profiles: profiles,
                portfolio: portfolio ?? InMemoryPortfolioRepository(),
              ),
              child: const WalletDetailsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'rename',
                builder: (_, _) => BlocProvider(
                  create: (_) => RenameWalletCubit(repository: profiles),
                  child: const RenameWalletScreen(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.showRecoveryPhrase,
            builder: (_, _) => const Scaffold(body: Text('recovery-stub')),
          ),
          GoRoute(
            path: Routes.exportPrivateKey,
            builder: (_, _) => const Scaffold(body: Text('export-stub')),
          ),
        ],
      );
      return MaterialApp.router(routerConfig: router);
    }

    void tallScreen(WidgetTester tester) {
      tester.view
        ..physicalSize = const Size(390, 1800)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    Future<void> openDetails(
      WidgetTester tester, {
      PortfolioRepository? portfolio,
    }) async {
      tallScreen(tester);
      await tester.pumpWidget(app(portfolio: portfolio));
      await tester.pumpAndSettle();
    }

    testWidgets('Wallet Details shows identity, value and every section',
        (tester) async {
      await openDetails(tester);

      expect(find.text('Wallet Details'), findsOneWidget);
      expect(find.text("Alex's Primary Vault"), findsOneWidget);
      expect(find.text('0x71C8...b94F9b'), findsOneWidget);
      expect(find.text('\$275,410.85'), findsOneWidget);
      expect(find.text('+7.4% (24H)'), findsOneWidget);
      expect(find.text('HARDWARE VAULT • ACTIVE'), findsOneWidget);

      expect(find.text('VAULT CREDENTIALS & SECURITY'), findsOneWidget);
      expect(find.text('Show Secret Recovery Phrase'), findsOneWidget);
      expect(find.text('Export Raw Private Key'), findsOneWidget);
      expect(find.text('DANGER'), findsOneWidget);
      expect(find.text("m/44'/60'/0'/0/0"), findsOneWidget);
      expect(find.text('Connected dApps'), findsOneWidget);
      expect(find.text('EXPLORERS & EXPORT'), findsOneWidget);
      expect(find.text('Etherscan Explorer'), findsOneWidget);
      expect(find.text('Export Activity CSV'), findsOneWidget);
      expect(find.text('DANGER ZONE'), findsOneWidget);
      expect(find.text('Remove Wallet'), findsOneWidget);
    });

    testWidgets('a falling balance is shown in the danger colour',
        (tester) async {
      final base =
          (await InMemoryPortfolioRepository().getSnapshot()).valueOrNull!;
      await openDetails(
        tester,
        portfolio: InMemoryPortfolioRepository(
          initialSnapshot: base.copyWith(change24hPercent: -3.2),
        ),
      );

      final text = tester.widget<Text>(find.text('-3.2% (24H)'));
      expect(text.style!.color, SettingsPalette.danger);
      expect(find.byIcon(Icons.trending_down_rounded), findsOneWidget);
    });

    testWidgets('shows a dash instead of a value when the balance is missing',
        (tester) async {
      await openDetails(tester, portfolio: _FailingPortfolio());

      expect(find.text("Alex's Primary Vault"), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.textContaining('(24H)'), findsNothing);
    });

    testWidgets('hides the derivation path row when there is none',
        (tester) async {
      profiles = _FakeProfiles(derivationPath: null);
      await openDetails(tester);

      expect(find.text('Derivation Path'), findsNothing);
      expect(find.text('Show Secret Recovery Phrase'), findsOneWidget);
    });

    testWidgets('explains derivation paths from the info button',
        (tester) async {
      await openDetails(tester);

      await tester.tap(find.byTooltip('About derivation paths'));
      await tester.pumpAndSettle();
      expect(find.textContaining('standard BIP-44 path'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.textContaining('standard BIP-44 path'), findsNothing);
    });

    testWidgets('shows a retryable failure when the profile cannot load',
        (tester) async {
      profiles = _FakeProfiles(loadFailure: const AppFailure.vaultLocked());
      await openDetails(tester);

      expect(find.text("Couldn't load wallet details"), findsOneWidget);

      profiles.loadFailure = null;
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(find.text("Alex's Primary Vault"), findsOneWidget);
    });

    testWidgets('secret rows open the existing reveal screens', (tester) async {
      await openDetails(tester);

      await tester.tap(find.text('Show Secret Recovery Phrase'));
      await tester.pumpAndSettle();
      expect(find.text('recovery-stub'), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export Raw Private Key'));
      await tester.pumpAndSettle();
      expect(find.text('export-stub'), findsOneWidget);
    });

    testWidgets('rows without a destination say so instead of doing nothing',
        (tester) async {
      await openDetails(tester);

      await tester.tap(find.text('Remove Wallet').last);
      await tester.pump();
      expect(find.text('Removing a wallet is not available yet'),
          findsOneWidget);

      await tester.tap(find.text('Etherscan Explorer'));
      await tester.pump();
      expect(find.text('Explorer links is not available yet'), findsOneWidget);

      await tester.tap(find.text('Export Activity CSV'));
      await tester.pump();
      expect(find.text('CSV export is not available yet'), findsOneWidget);
    });

    testWidgets('copies the full address to the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await openDetails(tester);

      await tester.tap(find.text('COPY'));
      await tester.pump();

      expect(copied, _address);
      expect(find.text('Address copied'), findsOneWidget);
    });

    testWidgets('shows the full address as a QR code', (tester) async {
      await openDetails(tester);

      await tester.tap(find.byIcon(Icons.qr_code_2_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text(_address), findsOneWidget);
    });

    testWidgets('renaming updates the name on Wallet Details', (tester) async {
      await openDetails(tester);

      await tester.tap(find.text("Alex's Primary Vault"));
      await tester.pumpAndSettle();
      expect(find.text('Rename Wallet'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Trading Stash');
      await tester.pump();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(profiles.renamed, ['Trading Stash']);
      expect(find.text('Wallet Details'), findsOneWidget);
      expect(find.text('Trading Stash'), findsOneWidget);
      expect(find.text('Wallet renamed'), findsOneWidget);
    });

    testWidgets('the avatar edit button also opens Rename Wallet',
        (tester) async {
      await openDetails(tester);

      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Rename Wallet'), findsOneWidget);
    });

    group('Rename Wallet', () {
      Future<void> openRename(WidgetTester tester) async {
        await openDetails(tester);
        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();
      }

      testWidgets('shows the current name, address and counter',
          (tester) async {
        await openRename(tester);

        expect(find.text('VAULT IDENTITY'), findsOneWidget);
        expect(find.text('CURRENT NAME'), findsOneWidget);
        expect(find.text("Alex's Primary Vault"), findsWidgets);
        expect(find.text('0x71C8...b94F9b'), findsOneWidget);
        expect(find.text('20 / 32'), findsOneWidget);
        expect(find.text('Must be 1-32 characters'), findsOneWidget);
        expect(find.text('Secure Enclave Storage'), findsOneWidget);
        for (final name in WalletName.suggestions) {
          expect(find.text(name), findsOneWidget);
        }
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          "Alex's Primary Vault",
        );
      });

      testWidgets('will not save an unchanged name', (tester) async {
        await openRename(tester);

        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();

        expect(profiles.renamed, isEmpty);
        expect(find.text('Rename Wallet'), findsOneWidget);
      });

      testWidgets('tapping a preset fills the field', (tester) async {
        await openRename(tester);

        await tester.tap(find.text('Trading Stash'));
        await tester.pump();

        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Trading Stash',
        );
        expect(find.text('13 / 32'), findsOneWidget);

        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();
        expect(profiles.renamed, ['Trading Stash']);
      });

      testWidgets('flags and refuses a blank name', (tester) async {
        await openRename(tester);

        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump();

        final hint = tester.widget<Text>(find.text('Must be 1-32 characters'));
        expect(hint.style!.color, SettingsPalette.danger);

        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();
        expect(profiles.renamed, isEmpty);
      });

      testWidgets('stops typing at 32 characters', (tester) async {
        await openRename(tester);

        await tester.enterText(find.byType(TextField), 'x' * 40);
        await tester.pump();

        expect(find.text('32 / 32'), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'x' * 32,
        );
      });

      testWidgets('reports a failed save and stays open', (tester) async {
        profiles = _FakeProfiles(
          renameFailure: const AppFailure.unknown('nope'),
        );
        await openRename(tester);

        await tester.enterText(find.byType(TextField), 'Trading Stash');
        await tester.pump();
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();

        expect(find.text("Couldn't save the name. Try again."),
            findsOneWidget);
        expect(find.text('Rename Wallet'), findsOneWidget);
      });

      testWidgets('Cancel leaves without renaming', (tester) async {
        await openRename(tester);

        await tester.enterText(find.byType(TextField), 'Trading Stash');
        await tester.pump();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(profiles.renamed, isEmpty);
        expect(find.text('Wallet Details'), findsOneWidget);
        expect(find.text("Alex's Primary Vault"), findsOneWidget);
      });
    });
  });

  testWidgets(
    'end to end: profile button → multi-wallet screen',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      // Wide like the existing portfolio tests: the test font is wider than
      // the real one and overflows the Portfolio cards at phone width.
      tester.view
        ..physicalSize = const Size(800, 1800)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final vault = await tester.runAsync(_vaultWithWallet);
      final wordlist = await tester.runAsync(Bip39Wordlist.load);
      await tester.pumpWidget(SmartWalletApp(vault: vault!, wordlist: wordlist!));
      await tester.pump();
      await tester.pump(AppDurations.splash + const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));

      // Portfolio → profile chip in the header.
      await tester.tap(find.byIcon(Icons.person));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // The header profile button opens the multi-wallet screen.
      expect(find.text('Wallets'), findsOneWidget);
      expect(find.text('Add Wallet'), findsOneWidget);
    },
  );
}
