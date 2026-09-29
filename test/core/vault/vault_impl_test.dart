import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/core/vault/envelope.dart';
import 'package:smart_wallet/core/vault/lockout_policy.dart';
import 'package:smart_wallet/core/vault/pin.dart';
import 'package:smart_wallet/core/vault/vault_impl.dart';
import 'package:smart_wallet/core/vault/vault_session.dart';
import 'package:wallet_core_ffi/wallet_core_ffi.dart' as wc;

import 'fakes.dart';

Future<T> _sameIsolateRunner<T>(FutureOr<T> Function() computation) =>
    Future(computation);

typedef _VaultFixture = ({
  VaultImpl vault,
  InMemoryEnvelopeStore envelopeStore,
  FakeVaultKeystore keystore,
});

_VaultFixture _buildVaultFixture({DateTime Function()? now}) {
  final envelopeStore = InMemoryEnvelopeStore();
  final keystore = FakeVaultKeystore();
  final vault = VaultImpl(
    walletCore: FakeWalletCoreGateway(),
    kdf: const FakeKeyDerivation(),
    keystore: keystore,
    envelopeStore: envelopeStore,
    lockoutPolicy: LockoutPolicy(
      InMemoryLockoutStore(),
      now: now ?? DateTime.now,
    ),
    session: VaultSession(),
    isolateRunner: _sameIsolateRunner,
  );
  return (vault: vault, envelopeStore: envelopeStore, keystore: keystore);
}

VaultImpl _buildVault({DateTime Function()? now}) =>
    _buildVaultFixture(now: now).vault;

Future<Envelope> _readEnvelope(
  _VaultFixture fixture,
  String walletId,
) async {
  final wrapped = await fixture.envelopeStore.readWrapped(walletId);
  final unwrapped = await fixture.keystore.unwrap(
    keyAlias: 'wallet_$walletId',
    wrapped: wrapped!,
  );
  return Envelope.fromJson(
    jsonDecode(utf8.decode(unwrapped)) as Map<String, Object?>,
  );
}

void main() {
  group('createWallet / importMnemonic / importPrivateKey', () {
    test('createWallet succeeds and leaves the vault unlocked', () async {
      final vault = _buildVault();
      final result = await vault.createWallet(pin: Pin('123456'));

      expect(result.isOk, isTrue);
      final accounts = await vault.accounts(result.valueOrNull!);
      expect(accounts.valueOrNull, hasLength(wc.CoinType.values.length));
    });

    test('importMnemonic rejects an invalid mnemonic', () async {
      final vault = _buildVault();
      final result = await vault.importMnemonic(
        'not a real mnemonic',
        pin: Pin('123456'),
      );
      expect(result.failureOrNull, const AppFailure.invalidMnemonic());
    });

    test('importMnemonic accepts a valid mnemonic', () async {
      final vault = _buildVault();
      final result = await vault.importMnemonic(
        FakeWalletCoreGateway.validMnemonics.first,
        pin: Pin('123456'),
      );
      expect(result.isOk, isTrue);
    });

    test('importPrivateKey rejects a wrong-length key', () async {
      final vault = _buildVault();
      final result = await vault.importPrivateKey(
        Uint8List(10),
        wc.CoinType.ethereum,
        pin: Pin('123456'),
      );
      expect(result.failureOrNull, const AppFailure.invalidPrivateKey());
    });

    test('importPrivateKey accepts a valid key', () async {
      final vault = _buildVault();
      final result = await vault.importPrivateKey(
        Uint8List(32),
        wc.CoinType.bitcoin,
        pin: Pin('123456'),
      );
      expect(result.isOk, isTrue);
    });
  });

  group('unlock', () {
    test('locks, then unlocks with the correct PIN', () async {
      final vault = _buildVault();
      await vault.createWallet(pin: Pin('123456'));

      vault.lock();
      final result = await vault.unlock(Pin('123456'));

      expect(result.isOk, isTrue);
    });

    test('wrong PIN fails to unlock (GCM tag check)', () async {
      final vault = _buildVault();
      await vault.createWallet(pin: Pin('123456'));
      vault.lock();

      final result = await vault.unlock(Pin('654321'));

      expect(result.failureOrNull, const AppFailure.wrongPin());
    });
  });

  group('lockout / backoff', () {
    test('5 wrong PINs lock out for 1 minute, escalating on repeat', () async {
      var now = DateTime(2026, 1, 1);
      final vault = _buildVault(now: () => now);
      await vault.createWallet(pin: Pin('123456'));
      vault.lock();

      for (var i = 0; i < 4; i++) {
        final r = await vault.unlock(Pin('000000'));
        expect(r.failureOrNull, const AppFailure.wrongPin());
      }
      final fifthFailure = await vault.unlock(Pin('000000'));
      expect(
        fifthFailure.failureOrNull,
        isA<VaultLockedOutFailure>().having(
          (f) => f.remaining,
          'remaining',
          const Duration(minutes: 1),
        ),
      );

      // Still locked out even with the correct PIN.
      final stillLockedOut = await vault.unlock(Pin('123456'));
      expect(stillLockedOut.failureOrNull, isA<VaultLockedOutFailure>());

      // Advance past the 1-minute window: correct PIN now works.
      now = now.add(const Duration(minutes: 1, seconds: 1));
      final afterWindow = await vault.unlock(Pin('123456'));
      expect(afterWindow.isOk, isTrue);
    });

    test('a successful unlock resets the failure counter', () async {
      final now = DateTime(2026, 1, 1);
      final vault = _buildVault(now: () => now);
      await vault.createWallet(pin: Pin('123456'));
      vault.lock();

      for (var i = 0; i < 4; i++) {
        await vault.unlock(Pin('000000'));
      }
      final success = await vault.unlock(Pin('123456'));
      expect(success.isOk, isTrue);

      vault.lock();
      for (var i = 0; i < 4; i++) {
        final r = await vault.unlock(Pin('000000'));
        expect(r.failureOrNull, const AppFailure.wrongPin());
      }
      // 5th failure since reset — 1-minute tier again, not escalated
      // straight to 15, since it takes 5 fresh failures per tier.
      final fifthAfterReset = await vault.unlock(Pin('000000'));
      expect(
        fifthAfterReset.failureOrNull,
        isA<VaultLockedOutFailure>().having(
          (f) => f.remaining,
          'remaining',
          const Duration(minutes: 1),
        ),
      );
    });
  });

  group('changePin', () {
    test('old PIN stops working and new PIN works after a change', () async {
      final vault = _buildVault();
      final created = await vault.createWallet(pin: Pin('123456'));
      final walletId = created.valueOrNull!;

      final changeResult = await vault.changePin(
        current: Pin('123456'),
        next: Pin('999999'),
      );
      expect(changeResult.isOk, isTrue);

      vault.lock();
      final oldPinResult = await vault.unlock(Pin('123456'));
      expect(oldPinResult.failureOrNull, const AppFailure.wrongPin());

      final newPinResult = await vault.unlock(Pin('999999'));
      expect(newPinResult.isOk, isTrue);

      final accounts = await vault.accounts(walletId);
      expect(accounts.isOk, isTrue);
    });

    test('changePin with the wrong current PIN leaves the old PIN valid',
        () async {
      final vault = _buildVault();
      await vault.createWallet(pin: Pin('123456'));

      final changeResult = await vault.changePin(
        current: Pin('000000'),
        next: Pin('999999'),
      );
      expect(changeResult.failureOrNull, const AppFailure.wrongPin());

      vault.lock();
      final oldPinStillWorks = await vault.unlock(Pin('123456'));
      expect(oldPinStillWorks.isOk, isTrue);
    });
  });

  group('removeWallet', () {
    test('removes the wallet and locks it out of the session', () async {
      final vault = _buildVault();
      final created = await vault.createWallet(pin: Pin('123456'));
      final walletId = created.valueOrNull!;

      final removeResult = await vault.removeWallet(
        walletId,
        pin: Pin('123456'),
      );
      expect(removeResult.isOk, isTrue);

      final accountsAfterRemoval = await vault.accounts(walletId);
      expect(accountsAfterRemoval.failureOrNull, const AppFailure.vaultLocked());
    });
  });

  group('envelope salts', () {
    test('each wallet gets its own random salt', () async {
      final fixture = _buildVaultFixture();
      final walletIds = <String>[];
      for (var i = 0; i < 5; i++) {
        final result = await fixture.vault.createWallet(pin: Pin('123456'));
        walletIds.add(result.valueOrNull!);
      }

      final salts = <String>{};
      for (final id in walletIds) {
        final envelope = await _readEnvelope(fixture, id);
        salts.add(envelope.salt);
      }
      expect(salts, hasLength(5));
    });
  });

  group('revealSecret', () {
    test('requires a Pin — there is no biometric-token overload', () async {
      final vault = _buildVault();
      final created = await vault.createWallet(pin: Pin('123456'));
      final walletId = created.valueOrNull!;

      final wrongPin = await vault.revealSecret(walletId, pin: Pin('000000'));
      expect(wrongPin.failureOrNull, const AppFailure.wrongPin());

      final rightPin = await vault.revealSecret(walletId, pin: Pin('123456'));
      expect(rightPin.isOk, isTrue);
    });
  });
}
