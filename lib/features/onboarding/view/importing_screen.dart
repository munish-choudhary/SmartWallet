import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/design_system/onboarding_scaffold.dart';
import '../../../core/result/result.dart';
import '../../../core/vault/vault.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/onboarding_import_holder.dart';
import '../data/onboarding_pin_holder.dart';
import '../view_model/onboarding_flow_cubit.dart';

/// Actually commits the import: consumes the pending mnemonic/private-key
/// (from [OnboardingImportHolder]) and the confirmed PIN (from
/// [OnboardingPinHolder]) — the only two places those secrets have lived
/// since they were entered — and calls the vault. Neither ever touched
/// Cubit/Bloc state or a route param.
class ImportingScreen extends StatefulWidget {
  const ImportingScreen({super.key});

  @override
  State<ImportingScreen> createState() => _ImportingScreenState();
}

class _ImportingScreenState extends State<ImportingScreen> {
  AppFailure? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final vault = context.read<Vault>();
    final pending = context.read<OnboardingImportHolder>().take();
    final pin = context.read<OnboardingPinHolder>().takeConfirmedPin();
    if (pending == null || pin == null) {
      setState(
        () => _error = const AppFailure.unknown('nothing to import'),
      );
      return;
    }

    final Result<WalletId> result;
    try {
      result = switch (pending) {
        PendingMnemonicImport(:final mnemonic) => await vault.importMnemonic(
          mnemonic,
          pin: pin,
        ),
        PendingPrivateKeyImport(:final key, :final coin) =>
          await vault.importPrivateKey(key, coin, pin: pin),
      };

      if (!mounted) return;
      final walletId = result.valueOrNull;
      if (walletId == null) {
        setState(() => _error = result.failureOrNull);
        return;
      }

      if (context.read<OnboardingFlowCubit>().state.biometricsEnabled) {
        await vault.enableBiometrics(pin: pin);
      }

      if (!mounted) return;
      context.read<OnboardingFlowCubit>().setCompletedWalletId(walletId);
      context.go(Routes.importSuccess);
    } finally {
      pin.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OnboardingScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error == null) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.importingTitle,
                style: AppTypography.headline,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.importingBody,
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(
                _messageFor(_error!, l10n),
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => context.go(Routes.importMethod),
                child: Text(l10n.commonBack),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _messageFor(AppFailure failure, AppLocalizations l10n) => switch (failure) {
  InvalidMnemonicFailure() || InvalidPrivateKeyFailure() =>
    l10n.importPhraseInvalidWord,
  _ => l10n.commonGenericError,
};
