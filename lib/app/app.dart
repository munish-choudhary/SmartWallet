import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/network/rpc_probe_service.dart';
import '../core/vault/vault.dart';
import '../features/dapp_browser/data/dapp_browser_repository.dart';
import '../features/dapp_browser/data/dapp_connection_repository.dart';
import '../features/dapp_browser/data/eip1193/dapp_interaction.dart';
import '../features/dapp_browser/data/eip1193/evm_read_client.dart';
import '../features/alerts/data/price_alerts_repository.dart';
import '../features/notifications/data/notifications_repository.dart';
import '../features/onboarding/data/add_wallet_gate.dart';
import '../features/onboarding/data/bip39_wordlist.dart';
import '../features/ai_assistant/data/ai_assistant_repository.dart';
import '../features/portfolio/data/portfolio_repository.dart';
import '../features/settings/data/custom_network_repository.dart';
import '../features/settings/data/secret_reveal_gateway.dart';
import '../features/settings/data/security_settings_repository.dart';
import '../features/settings/data/wallet_name_store.dart';
import '../features/settings/data/wallet_profile_repository.dart';
import '../features/walletconnect/data/in_memory_wallet_connect_repository.dart';
import '../features/walletconnect/data/wallet_account_source.dart';
import '../features/walletconnect/data/wallet_connect_repository.dart';
import '../features/walletconnect/view/widgets/wc_request_host.dart';
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
  // The root navigator is shared with the WalletConnect request host, which
  // must show review sheets above whatever screen is open.
  final _navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  late final router = buildRouter(navigatorKey: _navigatorKey);

  @override
  Widget build(BuildContext context) {
    // Vault/wordlist are app-wide (every feature will eventually need the
    // vault, not just onboarding) — provided here, above the router,
    // rather than scoped to the onboarding shell.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<Vault>.value(value: widget.vault),
        RepositoryProvider<Bip39Wordlist>.value(value: widget.wordlist),
        RepositoryProvider<AddWalletGate>(create: (_) => AddWalletGate()),
        RepositoryProvider<SecuritySettingsRepository>(
          create: (_) => InMemorySecuritySettingsRepository(),
        ),
        RepositoryProvider<SecretRevealGateway>(
          create: (_) => VaultSecretRevealGateway(widget.vault),
        ),
        RepositoryProvider<WalletProfileRepository>(
          create: (_) => VaultWalletProfileRepository(
            vault: widget.vault,
            names: SecureWalletNameStore(),
          ),
        ),
        // App-wide so Wallet Details shows the same balance (and favourites)
        // as the Portfolio screen instead of a second copy of the data.
        RepositoryProvider<PortfolioRepository>(
          create: (_) => InMemoryPortfolioRepository(),
        ),
        RepositoryProvider<AiAssistantRepository>(
          create: (ctx) => LocalAiAssistantRepository(
            portfolio: ctx.read<PortfolioRepository>(),
          ),
        ),
        RepositoryProvider<NotificationsRepository>(
          create: (_) => InMemoryNotificationsRepository(),
        ),
        RepositoryProvider<PriceAlertsRepository>(
          create: (_) => InMemoryPriceAlertsRepository(),
        ),
        RepositoryProvider<CustomNetworkRepository>(
          create: (_) => InMemoryCustomNetworkRepository(
            probeService: RpcProbeService(),
          ),
        ),
        // WalletConnect + dApp browser. All in-memory for now: the relay
        // (reown_walletkit), Drift persistence and `core/signing` are
        // follow-ups — see each interface's docs.
        RepositoryProvider<WalletAccountSource>(
          create: (_) => const InMemoryWalletAccountSource(),
        ),
        RepositoryProvider<WalletConnectRepository>(
          create: (context) => InMemoryWalletConnectRepository(
            accountSource: context.read<WalletAccountSource>(),
          ),
        ),
        RepositoryProvider<DappBrowserRepository>(
          create: (_) => InMemoryDappBrowserRepository(),
        ),
        RepositoryProvider<DappConnectionRepository>(
          create: (_) => InMemoryDappConnectionRepository(),
        ),
        RepositoryProvider<DappSigningGateway>(
          create: (_) => const UnavailableDappSigningGateway(),
        ),
        RepositoryProvider<EvmReadClient>(
          create: (_) => DioEvmReadClient(),
        ),
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
        builder: (context, child) => WcRequestHost(
          navigatorKey: _navigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
