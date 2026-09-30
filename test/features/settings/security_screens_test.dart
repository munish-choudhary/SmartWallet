import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math';
import 'dart:typed_data';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/core/vault/fake_vault.dart';
import 'package:smart_wallet/core/vault/pin.dart';
import 'package:smart_wallet/core/vault/vault.dart';
import 'package:smart_wallet/features/onboarding/data/bip39_wordlist.dart';
import 'package:smart_wallet/features/settings/data/auto_lock_option.dart';
import 'package:smart_wallet/features/settings/data/secret_reveal_gateway.dart';
import 'package:smart_wallet/features/settings/data/security_settings_repository.dart';
import 'package:smart_wallet/features/settings/view/export_private_key_screen.dart';
import 'package:smart_wallet/features/settings/view_model/auto_lock_cubit.dart';
import 'package:smart_wallet/features/settings/view_model/auto_lock_state.dart';

Future<FakeVault> _vaultWithKey(String pin) async {
  final vault = FakeVault(
    wordlist: await Bip39Wordlist.load(),
    random: Random(1),
  );
  await vault.importPrivateKey(
    Uint8List.fromList(List<int>.generate(32, (i) => i + 1)),
    CoinType.ethereum,
    pin: Pin(pin),
  );
  return vault;
}

void main() {
  group('VaultSecretRevealGateway', () {
    test('reveals the key with the right PIN, rejects wrong PIN', () async {
      final gateway = VaultSecretRevealGateway(await _vaultWithKey('246810'));
      expect(
        (await gateway.revealPrivateKey(Pin('111111'))).failureOrNull,
        isA<WrongPinFailure>(),
      );
      final ok = await gateway.revealPrivateKey(Pin('246810'));
      expect(ok.valueOrNull, hasLength(32));
    });

    test('exports a derived key for a mnemonic wallet', () async {
      final vault = FakeVault(
        wordlist: await Bip39Wordlist.load(),
        random: Random(1),
      );
      await vault.startPendingWallet();
      final words = (await vault.pendingPhraseForDisplay()).valueOrNull!;
      final challenge = (await vault.verificationChallenge()).valueOrNull!;
      await vault.confirmPendingWallet(
        answers: [for (final c in challenge.challenges) words[c.wordIndex - 1]],
        pin: Pin('246810'),
      );
      final gateway = VaultSecretRevealGateway(vault);
      expect((await gateway.revealPrivateKey(Pin('246810'))).valueOrNull, hasLength(32));
      expect((await gateway.revealRecoveryPhrase(Pin('246810'))).isOk, isTrue);
    });

    test('refuses the recovery phrase for an imported-key wallet', () async {
      final gateway = VaultSecretRevealGateway(await _vaultWithKey('246810'));
      expect(
        (await gateway.revealRecoveryPhrase(Pin('246810'))).isOk,
        isFalse,
      );
    });

    test('fails when there is no wallet', () async {
      final vault = FakeVault(
        wordlist: await Bip39Wordlist.load(),
        random: Random(1),
      );
      expect(
        (await vault.activeWalletId()).failureOrNull,
        isA<WalletNotFoundFailure>(),
      );
      expect(
        (await VaultSecretRevealGateway(vault).loadAccount()).isOk,
        isFalse,
      );
    });
  });

  group('AutoLockCubit', () {
    blocTest<AutoLockCubit, AutoLockState>(
      'loads, selects and saves',
      build: () =>
          AutoLockCubit(repository: InMemorySecuritySettingsRepository()),
      act: (c) async {
        await Future<void>.delayed(Duration.zero);
        c.select(AutoLockOption.fiveMinutes);
        await c.save();
      },
      expect: () => [
        const AutoLockState.ready(
          saved: AutoLockOption.oneMinute,
          selected: AutoLockOption.oneMinute,
        ),
        const AutoLockState.ready(
          saved: AutoLockOption.oneMinute,
          selected: AutoLockOption.fiveMinutes,
        ),
        const AutoLockState.ready(
          saved: AutoLockOption.oneMinute,
          selected: AutoLockOption.fiveMinutes,
          saving: true,
        ),
        const AutoLockState.ready(
          saved: AutoLockOption.fiveMinutes,
          selected: AutoLockOption.fiveMinutes,
          justSaved: true,
        ),
      ],
    );
  });

  testWidgets('export key stays locked until the correct PIN is entered',
      (tester) async {
    final vault = await tester.runAsync(() => _vaultWithKey('246810'));
    await tester.pumpWidget(
      RepositoryProvider<SecretRevealGateway>(
        create: (_) => VaultSecretRevealGateway(vault!),
        child: const MaterialApp(home: ExportPrivateKeyScreen()),
      ),
    );

    Future<void> enter(String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.text(d).first);
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    await enter('111111');
    expect(find.text('Incorrect PIN. Try again.'), findsOneWidget);
    expect(find.text('EXTREME CAUTION'), findsNothing);

    await enter('246810');
    expect(find.text('EXTREME CAUTION'), findsOneWidget);
    expect(find.text('Tap to Reveal Secret Key'), findsOneWidget);

    await tester.ensureVisible(find.text('QR Code'));
    await tester.tap(find.text('QR Code'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);

    await tester.ensureVisible(find.text('Tap to Reveal Secret Key'));
    await tester.tap(find.text('Tap to Reveal Secret Key'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
  });
}
