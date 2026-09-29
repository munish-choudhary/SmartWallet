import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/vault/vault.dart';
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
import '../features/onboarding/view/welcome_screen.dart';
import '../features/onboarding/view_model/onboarding_flow_cubit.dart';
import '../features/portfolio/data/portfolio_repository.dart';
import '../features/portfolio/view/portfolio_screen.dart';
import '../features/portfolio/view_model/portfolio_cubit.dart';
import 'routes.dart';
import 'theme/app_durations.dart';

/// `Vault`/`Bip39Wordlist` are provided above this router (in `app.dart`)
/// since they're app-wide; this only wires routes and onboarding-scoped
/// state (reset fresh each time the onboarding shell is entered).
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: Routes.splash,
    redirect: (context, state) async {
      // Per CLAUDE.md's routing rules extended for onboarding: once a
      // wallet exists, onboarding is unreachable, no matter how it's
      // navigated to — the splash screen's own check only covers the
      // initial launch.
      if (!state.matchedLocation.startsWith(Routes.onboarding)) return null;
      final hasWallet = await context.read<Vault>().hasAnyWallet();
      return hasWallet ? Routes.portfolio : null;
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
              create: (_) => OnboardingFlowCubit(),
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
          RepositoryProvider<PortfolioRepository>(
            create: (_) => InMemoryPortfolioRepository(),
            child: BlocProvider<PortfolioCubit>(
              create: (context) => PortfolioCubit(
                repository: context.read<PortfolioRepository>(),
              ),
              child: const PortfolioScreen(),
            ),
          ),
        ),
      ),
    ],
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
