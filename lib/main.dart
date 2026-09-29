import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/vault/fake_vault.dart';
import 'features/onboarding/data/bip39_wordlist.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final wordlist = await Bip39Wordlist.load();
  // Always a FakeVault for now — see lib/core/vault/README.md and
  // lib/core/vault/fake_vault.dart's header for why, and swap this for a
  // real VaultImpl once wallet_core_ffi has real bindings.
  final vault = FakeVault(wordlist: wordlist);
  runApp(SmartWalletApp(vault: vault, wordlist: wordlist));
}
