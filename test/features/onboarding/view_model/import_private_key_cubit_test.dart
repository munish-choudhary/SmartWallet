import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/vault/fake_vault.dart';
import 'package:smart_wallet/core/vault/vault.dart';
import 'package:smart_wallet/features/onboarding/data/bip39_wordlist.dart';
import 'package:smart_wallet/features/onboarding/view_model/import_private_key_cubit.dart';

void main() {
  late FakeVault vault;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final wordlist = await Bip39Wordlist.load();
    vault = FakeVault(wordlist: wordlist);
  });

  group('ImportPrivateKeyCubit', () {
    blocTest<ImportPrivateKeyCubit, ImportPrivateKeyState>(
      'a 64-char hex key is valid for EVM',
      build: () => ImportPrivateKeyCubit(vault: vault),
      act: (cubit) => cubit.setRawKey('a' * 64),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) => expect(cubit.state.formatValid, isTrue),
    );

    blocTest<ImportPrivateKeyCubit, ImportPrivateKeyState>(
      'a too-short key is invalid',
      build: () => ImportPrivateKeyCubit(vault: vault),
      act: (cubit) => cubit.setRawKey('abc123'),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) => expect(cubit.state.formatValid, isFalse),
    );

    blocTest<ImportPrivateKeyCubit, ImportPrivateKeyState>(
      'switching network re-validates the current key against the new family',
      build: () => ImportPrivateKeyCubit(vault: vault),
      act: (cubit) async {
        // '0' isn't in the Base58 alphabet, so this is valid EVM hex but
        // invalid as a Solana key.
        cubit.setRawKey('0' * 64);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        cubit.setNetwork(CoinType.solana);
      },
      wait: const Duration(milliseconds: 10),
      verify: (cubit) => expect(cubit.state.formatValid, isFalse),
    );
  });
}
