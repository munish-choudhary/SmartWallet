import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/vault/vault.dart';
import '../features/onboarding/data/bip39_wordlist.dart';
import '../l10n/gen/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class SmartWalletApp extends StatefulWidget {
  const SmartWalletApp({super.key, required this.vault, required this.wordlist});

  final Vault vault;
  final Bip39Wordlist wordlist;

  @override
  State<SmartWalletApp> createState() => _SmartWalletAppState();
}

class _SmartWalletAppState extends State<SmartWalletApp> {
  late final router = buildRouter();

  @override
  Widget build(BuildContext context) {
    // Vault/wordlist are app-wide (every feature will eventually need the
    // vault, not just onboarding) — provided here, above the router,
    // rather than scoped to the onboarding shell.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<Vault>.value(value: widget.vault),
        RepositoryProvider<Bip39Wordlist>.value(value: widget.wordlist),
      ],
      child: MaterialApp.router(
        title: 'Lexor Pocket',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }
}
