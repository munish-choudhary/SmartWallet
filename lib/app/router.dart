import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/vault/vault.dart';
import '../features/dapp_browser/data/dapp_browser_repository.dart';
import '../features/dapp_browser/data/dapp_connection_repository.dart';
import '../features/dapp_browser/data/eip1193/dapp_interaction.dart';
import '../features/dapp_browser/data/eip1193/eip1193_bridge.dart';
import '../features/dapp_browser/data/eip1193/evm_read_client.dart';
import '../features/dapp_browser/view/dapp_browser_screen.dart';
import '../features/dapp_browser/view/dapp_web_view_screen.dart';
import '../features/dapp_browser/view_model/dapp_browser_cubit.dart';
import '../features/dapp_browser/view_model/dapp_web_view_cubit.dart';
import '../features/onboarding/data/add_wallet_gate.dart';
import '../features/onboarding/data/onboarding_import_holder.dart';
import '../features/onboarding/data/onboarding_pin_holder.dart';
import '../features/onboarding/view/backup_warning_screen.dart';
import '../features/onboarding/view/biometrics_prompt_screen.dart';
import '../features/onboarding/view/confirm_pin_screen.dart';
import '../features/onboarding/view/create_pin_screen.dart';
import '../features/onboarding/view/creation_success_screen.dart';
import '../features/onboarding/view/import_method_screen.dart';
import '../features/onboarding/view/import_phrase_screen.dart';
import '../features/onboarding/view/import_private_key_screen.dart';
import '../features/onboarding/view/import_success_screen.dart';
import '../features/onboarding/view/importing_screen.dart';
import '../features/onboarding/view/recovery_phrase_screen.dart';
import '../features/onboarding/view/setup_choice_screen.dart';
import '../features/onboarding/view/splash_screen.dart';
import '../features/onboarding/view/verify_phrase_screen.dart';
import '../features/onboarding/view/verify_pin_screen.dart';
import '../features/onboarding/view/welcome_screen.dart';
import '../features/onboarding/view_model/onboarding_flow_cubit.dart';
import '../features/alerts/data/price_alerts_repository.dart';
import '../features/alerts/view/price_alerts_screen.dart';
import '../features/alerts/view_model/price_alerts_cubit.dart';
import '../features/ai_assistant/data/ai_assistant_repository.dart';
import '../features/ai_assistant/view/ai_assistant_screen.dart';
import '../features/ai_assistant/view_model/ai_chat_cubit.dart';
import '../features/buy_sell/view/buy_sell_screen.dart';
import '../features/buy_sell/view_model/buy_sell_cubit.dart';
import '../features/notifications/data/notifications_repository.dart';
import '../features/notifications/view/notifications_screen.dart';
import '../features/notifications/view_model/notifications_cubit.dart';
import '../features/portfolio/data/portfolio_repository.dart';
import '../features/portfolio/view/add_custom_token_screen.dart';
import '../features/portfolio/view/manage_token_list_screen.dart';
import '../features/portfolio/view_model/add_custom_token_cubit.dart';
import '../features/portfolio/view_model/manage_tokens_cubit.dart';
import '../features/portfolio/view/portfolio_screen.dart';
import '../features/portfolio/view_model/portfolio_cubit.dart';
import '../features/settings/data/custom_network_repository.dart';
import '../features/settings/data/security_settings_repository.dart';
import '../features/settings/view/add_custom_network_screen.dart';
import '../features/settings/view/auto_lock_timer_screen.dart';
import '../features/settings/view/balance_privacy_screen.dart';
import '../features/settings/view/export_private_key_screen.dart';
import '../features/settings/data/wallet_profile_repository.dart';
import '../features/settings/view/help_about_screen.dart';
import '../features/settings/view/rename_wallet_screen.dart';
import '../features/settings/view/security_settings_screen.dart';
import '../features/settings/view/show_recovery_phrase_screen.dart';
import '../features/settings/view/wallet_details_screen.dart';
import '../features/settings/view/wallets_screen.dart';
import '../features/settings/view_model/add_custom_network_cubit.dart';
import '../features/settings/view_model/auto_lock_cubit.dart';
import '../features/settings/view_model/balance_privacy_cubit.dart';
import '../features/settings/view_model/rename_wallet_cubit.dart';
import '../features/settings/view_model/wallet_details_cubit.dart';
import '../features/settings/view_model/wallets_cubit.dart';
import '../features/walletconnect/data/wallet_account_source.dart';
import '../features/walletconnect/data/wallet_connect_repository.dart';
import '../features/walletconnect/view/connected_app_detail_screen.dart';
import '../features/walletconnect/view/connected_success_screen.dart';
import '../features/walletconnect/view/connecting_pairing_screen.dart';
import '../features/walletconnect/view/qr_scanner_screen.dart';
import '../features/walletconnect/view/wallet_connect_screen.dart';
import '../features/walletconnect/view_model/pairing_cubit.dart';
import '../features/walletconnect/view_model/session_detail_cubit.dart';
import '../features/walletconnect/view_model/wallet_connect_cubit.dart';
import 'routes.dart';
import 'theme/app_durations.dart';

/// `Vault`/`Bip39Wordlist` are provided above this router (in `app.dart`)
/// since they're app-wide; this only wires routes and onboarding-scoped
/// state (reset fresh each time the onboarding shell is entered).
GoRouter buildRouter({GlobalKey<NavigatorState>? navigatorKey}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: Routes.splash,
    redirect: (context, state) async {
      // Per CLAUDE.md's routing rules extended for onboarding: once a
      // wallet exists, onboarding is unreachable, no matter how it's
      // navigated to — the splash screen's own check only covers the
      // initial launch. The one exception is the add-another-wallet flow,
      // which the Wallets screen opens the gate for.
      if (!state.matchedLocation.startsWith(Routes.onboarding)) return null;
      final vault = context.read<Vault>();
      final gate = context.read<AddWalletGate>();
      if (!await vault.hasAnyWallet()) return null;
      return gate.isOpen ? null : Routes.portfolio;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) =>
            _page(state, const SplashScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MultiRepositoryProvider(
            providers: [
              RepositoryProvider<OnboardingPinHolder>(
                create: (_) => OnboardingPinHolder(),
              ),
              RepositoryProvider<OnboardingImportHolder>(
                create: (_) => OnboardingImportHolder(),
              ),
            ],
            child: BlocProvider(
              create: (context) =>
                  OnboardingFlowCubit(vault: context.read<Vault>()),
              child: child,
            ),
          );
        },
        routes: [
          GoRoute(
            path: Routes.welcome,
            pageBuilder: (context, state) =>
                _page(state, const WelcomeScreen()),
          ),
          GoRoute(
            path: Routes.setupChoice,
            pageBuilder: (context, state) =>
                _page(state, const SetupChoiceScreen()),
          ),
          // Entry of the add-another-wallet flow (Wallets screen's "+").
          GoRoute(
            path: Routes.addWallet,
            pageBuilder: (context, state) =>
                _page(state, const SetupChoiceScreen(addMode: true)),
          ),
          GoRoute(
            path: Routes.verifyPin,
            pageBuilder: (context, state) =>
                _page(state, const VerifyPinScreen()),
          ),
          GoRoute(
            path: Routes.createPin,
            pageBuilder: (context, state) =>
                _page(state, const CreatePinScreen()),
          ),
          GoRoute(
            path: Routes.confirmPin,
            pageBuilder: (context, state) =>
                _page(state, const ConfirmPinScreen()),
          ),
          GoRoute(
            path: Routes.biometricsPrompt,
            pageBuilder: (context, state) =>
                _page(state, const BiometricsPromptScreen()),
          ),
          GoRoute(
            path: Routes.backupWarning,
            pageBuilder: (context, state) =>
                _page(state, const BackupWarningScreen()),
          ),
          GoRoute(
            path: Routes.recoveryPhrase,
            pageBuilder: (context, state) =>
                _page(state, const RecoveryPhraseScreen()),
          ),
          GoRoute(
            path: Routes.verifyPhrase,
            pageBuilder: (context, state) =>
                _page(state, const VerifyPhraseScreen()),
          ),
          GoRoute(
            path: Routes.creationSuccess,
            pageBuilder: (context, state) =>
                _page(state, const CreationSuccessScreen()),
          ),
          GoRoute(
            path: Routes.importMethod,
            pageBuilder: (context, state) =>
                _page(state, const ImportMethodScreen()),
          ),
          GoRoute(
            path: Routes.importPhrase,
            pageBuilder: (context, state) =>
                _page(state, const ImportPhraseScreen()),
          ),
          GoRoute(
            path: Routes.importPrivateKey,
            pageBuilder: (context, state) =>
                _page(state, const ImportPrivateKeyScreen()),
          ),
          GoRoute(
            path: Routes.importing,
            pageBuilder: (context, state) =>
                _page(state, const ImportingScreen()),
          ),
          GoRoute(
            path: Routes.importSuccess,
            pageBuilder: (context, state) =>
                _page(state, const ImportSuccessScreen()),
          ),
        ],
      ),
      GoRoute(
        path: Routes.portfolio,
        pageBuilder: (context, state) => _page(
          state,
          // `PortfolioRepository` is provided at the app root (see app.dart)
          // so Wallet Details reads the same data.
          MultiBlocProvider(
            providers: [
              BlocProvider<PortfolioCubit>(
                create: (context) => PortfolioCubit(
                  repository: context.read<PortfolioRepository>(),
                ),
              ),
              // Drives the unread badge on the header bell.
              BlocProvider<NotificationsCubit>(
                create: (context) => NotificationsCubit(
                  repository: context.read<NotificationsRepository>(),
                ),
              ),
            ],
            child: const PortfolioScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.aiAssistant,
        pageBuilder: (context, state) => _page(
          state,
          BlocProvider(
            create: (context) => AiChatCubit(
              repository: context.read<AiAssistantRepository>(),
            ),
            child: AiAssistantScreen(
              tokenSymbol: state.uri.queryParameters['token'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: Routes.buySell,
        pageBuilder: (context, state) => _page(
          state,
          BlocProvider(
            create: (context) => BuySellCubit(
              repository: context.read<PortfolioRepository>(),
            ),
            child: const BuySellScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.manageTokens,
        pageBuilder: (context, state) => _page(
          state,
          BlocProvider(
            create: (context) => ManageTokensCubit(
              repository: context.read<PortfolioRepository>(),
            ),
            child: const ManageTokenListScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.addCustomToken,
        pageBuilder: (context, state) => _page(
          state,
          BlocProvider(
            create: (context) => AddCustomTokenCubit(
              repository: context.read<PortfolioRepository>(),
            ),
            child: const AddCustomTokenScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.priceAlerts,
        pageBuilder: (context, state) => _page(
          state,
          BlocProvider(
            create: (context) => PriceAlertsCubit(
              alerts: context.read<PriceAlertsRepository>(),
              portfolio: context.read<PortfolioRepository>(),
            ),
            child: const PriceAlertsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.notifications,
        pageBuilder: (context, state) => _page(
          state,
          BlocProvider(
            create: (context) => NotificationsCubit(
              repository: context.read<NotificationsRepository>(),
            ),
            child: const NotificationsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.securitySettings,
        pageBuilder: (context, state) =>
            _page(state, const SecuritySettingsScreen()),
        routes: [
          GoRoute(
            path: 'auto-lock',
            pageBuilder: (context, state) => _page(
              state,
              BlocProvider(
                create: (context) => AutoLockCubit(
                  repository: context.read<SecuritySettingsRepository>(),
                ),
                child: const AutoLockTimerScreen(),
              ),
            ),
          ),
          GoRoute(
            path: 'balance-privacy',
            pageBuilder: (context, state) => _page(
              state,
              BlocProvider(
                create: (context) => BalancePrivacyCubit(
                  repository: context.read<SecuritySettingsRepository>(),
                ),
                child: const BalancePrivacyScreen(),
              ),
            ),
          ),
          GoRoute(
            path: 'recovery-phrase',
            pageBuilder: (context, state) =>
                _page(state, const ShowRecoveryPhraseScreen()),
          ),
          GoRoute(
            path: 'export-private-key',
            pageBuilder: (context, state) =>
                _page(state, const ExportPrivateKeyScreen()),
          ),
        ],
      ),
      GoRoute(
        path: Routes.helpAbout,
        pageBuilder: (context, state) =>
            _page(state, const HelpAboutScreen()),
      ),
      GoRoute(
        path: Routes.addCustomNetwork,
        pageBuilder: (context, state) => _page(
          state,
          BlocProvider(
            create: (context) => AddCustomNetworkCubit(
              repository: context.read<CustomNetworkRepository>(),
            ),
            child: const AddCustomNetworkScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.walletDetails,
        pageBuilder: (context, state) => _page(
          state,
          BlocProvider(
            create: (context) => WalletDetailsCubit(
              profiles: context.read<WalletProfileRepository>(),
              portfolio: context.read<PortfolioRepository>(),
            ),
            child: const WalletDetailsScreen(),
          ),
        ),
        routes: [
          GoRoute(
            path: 'all',
            pageBuilder: (context, state) => _page(
              state,
              BlocProvider(
                create: (context) => WalletsCubit(
                  profiles: context.read<WalletProfileRepository>(),
                ),
                child: const WalletsScreen(),
              ),
            ),
          ),
          GoRoute(
            path: 'rename',
            pageBuilder: (context, state) => _page(
              state,
              BlocProvider(
                create: (context) => RenameWalletCubit(
                  repository: context.read<WalletProfileRepository>(),
                ),
                child: const RenameWalletScreen(),
              ),
            ),
          ),
        ],
      ),
      // WalletConnect: the hub, pairing and success screens share one
      // PairingCubit (the pairing link never travels through a route).
      ShellRoute(
        builder: (context, state, child) => MultiBlocProvider(
          providers: [
            BlocProvider<WalletConnectCubit>(
              create: (context) => WalletConnectCubit(
                repository: context.read<WalletConnectRepository>(),
              ),
            ),
            BlocProvider<PairingCubit>(
              create: (context) => PairingCubit(
                repository: context.read<WalletConnectRepository>(),
              ),
            ),
          ],
          child: child,
        ),
        routes: [
          GoRoute(
            path: Routes.walletConnect,
            pageBuilder: (context, state) =>
                _page(state, const WalletConnectScreen()),
            routes: [
              GoRoute(
                path: 'pairing',
                pageBuilder: (context, state) =>
                    _page(state, const ConnectingPairingScreen()),
              ),
              GoRoute(
                path: 'scan',
                pageBuilder: (context, state) =>
                    _page(state, const QrScannerScreen()),
              ),
              GoRoute(
                path: 'connected',
                pageBuilder: (context, state) =>
                    _page(state, const ConnectedSuccessScreen()),
              ),
              GoRoute(
                path: 'session/:topic',
                pageBuilder: (context, state) => _page(
                  state,
                  BlocProvider(
                    create: (context) => SessionDetailCubit(
                      topic: state.pathParameters['topic']!,
                      repository: context.read<WalletConnectRepository>(),
                    ),
                    child: const ConnectedAppDetailScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.dapps,
        pageBuilder: (context, state) => _page(
          state,
          BlocProvider(
            create: (context) => DappBrowserCubit(
              repository: context.read<DappBrowserRepository>(),
            ),
            child: const DappBrowserScreen(),
          ),
        ),
        routes: [
          // Plain platform transition: the page hosts a platform view, and
          // fade/slide layers over one are costly (CLAUDE.md, Performance).
          GoRoute(
            path: 'browse',
            builder: (context, state) => BlocProvider(
              create: (context) => _buildWebViewCubit(
                context,
                rawUrl: state.uri.queryParameters['url'] ?? '',
              ),
              child: const DappWebViewScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

DappWebViewCubit _buildWebViewCubit(
  BuildContext context, {
  required String rawUrl,
}) {
  final connections = context.read<DappConnectionRepository>();
  final broker = DappPromptBroker();
  return DappWebViewCubit(
    rawUrl: rawUrl,
    browserRepository: context.read<DappBrowserRepository>(),
    connections: connections,
    bridge: Eip1193Bridge(
      connections: connections,
      accounts: context.read<WalletAccountSource>(),
      prompter: broker,
      signer: context.read<DappSigningGateway>(),
      reader: context.read<EvmReadClient>(),
    ),
    broker: broker,
  );
}

CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.pageTransition,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
