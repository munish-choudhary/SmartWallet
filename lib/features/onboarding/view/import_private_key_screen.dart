import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/design_system/glass_card.dart';
import '../../../core/design_system/onboarding_scaffold.dart';
import '../../../core/design_system/pill_button.dart';
import '../../../core/design_system/warning_card.dart';
import '../../../core/security/screen_protection_mixin.dart';
import '../../../core/vault/base58.dart';
import '../../../core/vault/vault.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/onboarding_import_holder.dart';
import 'pin_entry_navigation.dart';
import '../view_model/import_private_key_cubit.dart';

Map<CoinType, String> _networkLabels(AppLocalizations l10n) => {
  CoinType.ethereum: l10n.networkEthereum,
  CoinType.smartChain: l10n.networkSmartChain,
  CoinType.polygon: l10n.networkPolygon,
  CoinType.arbitrum: l10n.networkArbitrum,
  CoinType.base: l10n.networkBase,
  CoinType.solana: l10n.networkSolana,
  CoinType.tron: l10n.networkTron,
  CoinType.bitcoin: l10n.networkBitcoin,
};

class ImportPrivateKeyScreen extends StatelessWidget {
  const ImportPrivateKeyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ImportPrivateKeyCubit(vault: context.read<Vault>()),
      child: const _ImportPrivateKeyView(),
    );
  }
}

class _ImportPrivateKeyView extends StatefulWidget {
  const _ImportPrivateKeyView();

  @override
  State<_ImportPrivateKeyView> createState() => _ImportPrivateKeyViewState();
}

class _ImportPrivateKeyViewState extends State<_ImportPrivateKeyView>
    with ScreenProtectionMixin<_ImportPrivateKeyView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue(BuildContext context, ImportPrivateKeyState state) {
    final normalized = state.rawKey.startsWith('0x')
        ? state.rawKey.substring(2)
        : state.rawKey;
    final bytes = state.network.chainFamily == ChainFamily.solana
        ? decodeBase58(state.rawKey)
        : _hexToBytes(normalized);
    context.read<OnboardingImportHolder>().storePrivateKey(
      bytes,
      state.network,
    );
    context.pushPinEntry();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OnboardingScaffold(
      onBack: () => context.pop(),
      body: BlocBuilder<ImportPrivateKeyCubit, ImportPrivateKeyState>(
        builder: (context, state) {
          final cubit = context.read<ImportPrivateKeyCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.importKeyTitle,
                textAlign: TextAlign.center,
                style: AppTypography.headline,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.importKeySubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.importKeyNetwork, style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CoinType>(
                    value: state.network,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceElevated,
                    style: AppTypography.bodyStrong,
                    items: [
                      for (final entry in _networkLabels(l10n).entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                    ],
                    onChanged: (network) {
                      if (network != null) cubit.setNetwork(network);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.importKeyHexLabel, style: AppTypography.label),
                  TextButton.icon(
                    onPressed: cubit.toggleObscured,
                    icon: Icon(
                      state.obscured
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 16,
                    ),
                    label: Text(
                      state.obscured ? l10n.importKeyShow : l10n.importKeyHide,
                    ),
                  ),
                ],
              ),
              GlassCard(
                child: TextField(
                  controller: _controller,
                  obscureText: state.obscured,
                  maxLines: state.obscured ? 1 : 3,
                  style: AppTypography.mono,
                  enableSuggestions: false,
                  autocorrect: false,
                  enableIMEPersonalizedLearning: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                  onChanged: cubit.setRawKey,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final data = await Clipboard.getData(
                          Clipboard.kTextPlain,
                        );
                        final text = data?.text;
                        if (text == null) return;
                        _controller.text = text;
                        cubit.setRawKey(text);
                      },
                      icon: const Icon(Icons.paste, size: 16),
                      label: Text(l10n.importKeyPaste),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(content: Text(l10n.importKeyScanQrComingSoon)),
                      ),
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: Text(l10n.importKeyScanQr),
                    ),
                  ),
                ],
              ),
              if (state.rawKey.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.formatValid
                      ? l10n.importKeyFormatValid
                      : l10n.importPhraseInvalidWord,
                  style: AppTypography.caption.copyWith(
                    color: state.formatValid
                        ? AppColors.accent
                        : AppColors.danger,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              WarningCard(
                title: l10n.importKeyWarningTitle,
                subtitle: l10n.importKeyWarningBody,
              ),
            ],
          );
        },
      ),
      footer: BlocBuilder<ImportPrivateKeyCubit, ImportPrivateKeyState>(
        builder: (context, state) {
          return PillButton(
            label: l10n.importWallet,
            icon: Icons.arrow_forward,
            onPressed: state.formatValid
                ? () => _continue(context, state)
                : null,
          );
        },
      ),
    );
  }
}

Uint8List _hexToBytes(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);
