import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../data/wallet_profile.dart';
import '../view_model/wallet_details_cubit.dart';
import '../view_model/wallet_details_state.dart';
import 'add_wallet_launcher.dart';
import 'widgets/glass_group.dart';
import 'widgets/settings_palette.dart';
import 'widgets/settings_sub_header.dart';
import 'widgets/wallet_identity_card.dart';
import 'widgets/wallet_qr_sheet.dart';

/// Home → profile: identity, key management, explorers and the danger zone
/// for the active wallet.
///
/// Rows whose destination doesn't exist yet (external links need a link
/// launcher, CSV export and wallet removal aren't built) say "not available
/// yet" like the unbuilt rows on Security Settings, instead of doing nothing.
class WalletDetailsScreen extends StatelessWidget {
  const WalletDetailsScreen({super.key});

  void _comingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what is not available yet')));
  }

  Future<void> _rename(BuildContext context) async {
    final renamed = await context.push<String>(Routes.renameWallet);
    if (renamed != null && context.mounted) {
      await context.read<WalletDetailsCubit>().refresh();
    }
  }

  Future<void> _openWallets(BuildContext context) async {
    final cubit = context.read<WalletDetailsCubit>();
    await context.push<void>(Routes.wallets);
    // The active wallet may have changed while the list was open.
    if (!cubit.isClosed) await cubit.refresh();
  }

  Future<void> _addWallet(BuildContext context) async {
    final cubit = context.read<WalletDetailsCubit>();
    await startAddWallet(context);
    if (!cubit.isClosed) await cubit.refresh();
  }

  Future<void> _copyAddress(BuildContext context, String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Address copied')));
  }

  void _showDerivationInfo(BuildContext context, String path) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SettingsPalette.card,
        title: const Text(
          'Derivation Path',
          style: TextStyle(color: SettingsPalette.textPrimary, fontSize: 20),
        ),
        content: Text(
          '$path is the standard BIP-44 path for Ethereum accounts. It tells '
          'your recovery phrase which key belongs to this address, so '
          'restoring the same phrase in any compatible wallet gives you the '
          'same account.',
          style: const TextStyle(
            color: SettingsPalette.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it',
              style: TextStyle(color: SettingsPalette.accent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'Wallet Details',
      ambient: const _WalletAmbient(),
      headerTrailing: Builder(
        builder: (context) =>
            _HeaderAddButton(onPressed: () => _addWallet(context)),
      ),
      child: BlocBuilder<WalletDetailsCubit, WalletDetailsState>(
        builder: (context, state) => switch (state) {
          WalletDetailsLoading() =>
            const Center(child: CircularProgressIndicator()),
          WalletDetailsFailure() => _LoadFailure(
              onRetry: context.read<WalletDetailsCubit>().load,
            ),
          WalletDetailsLoaded(:final profile, :final portfolio) => ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                WalletIdentityCard(
                  profile: profile,
                  portfolio: portfolio,
                  onRename: () => _rename(context),
                  onCopyAddress: () => _copyAddress(context, profile.address),
                  onShowQr: () => showWalletQrSheet(
                    context,
                    address: profile.address,
                    onCopy: () => _copyAddress(context, profile.address),
                  ),
                ),
                const SizedBox(height: 24),
                GlassGroupCard(
                  children: [
                    GlassRowTile(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: SettingsPalette.accent,
                      title: 'My Wallets',
                      subtitle: 'Switch between or add wallets',
                      trailing: const GlassChevron(),
                      onTap: () => _openWallets(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SecuritySection(
                  derivationPath: profile.derivationPath,
                  onShowDerivationInfo: (path) =>
                      _showDerivationInfo(context, path),
                  onConnectedApps: () => context.push(Routes.walletConnect),
                ),
                const SizedBox(height: 24),
                _ExplorersSection(
                  profile: profile,
                  onExplorer: () => _comingSoon(context, 'Explorer links'),
                  onExport: () => _comingSoon(context, 'CSV export'),
                ),
                const SizedBox(height: 24),
                _DangerZone(
                  onRemove: () => _comingSoon(context, 'Removing a wallet'),
                ),
              ],
            ),
        },
      ),
    );
  }
}

class _SecuritySection extends StatelessWidget {
  const _SecuritySection({
    required this.derivationPath,
    required this.onShowDerivationInfo,
    required this.onConnectedApps,
  });

  final String? derivationPath;
  final ValueChanged<String> onShowDerivationInfo;
  final VoidCallback onConnectedApps;

  @override
  Widget build(BuildContext context) {
    final path = derivationPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GlassSectionLabel('Vault credentials & security'),
        GlassGroupCard(
          children: [
            GlassRowTile(
              icon: Icons.key_rounded,
              iconColor: SettingsPalette.accent,
              title: 'Show Secret Recovery Phrase',
              subtitle: 'Reveal your master seed backup',
              trailing: const GlassChevron(),
              onTap: () => context.push(Routes.showRecoveryPhrase),
            ),
            GlassRowTile(
              icon: Icons.vpn_key_outlined,
              iconColor: SettingsPalette.accent,
              title: 'Export Raw Private Key',
              subtitle: 'Export the raw key for one chain',
              badge: const GlassBadge(
                'DANGER',
                background: SettingsPalette.chip,
                foreground: SettingsPalette.danger,
              ),
              trailing: const GlassChevron(),
              onTap: () => context.push(Routes.exportPrivateKey),
            ),
            if (path != null)
              GlassRowTile(
                icon: Icons.account_tree_outlined,
                title: 'Derivation Path',
                subtitle: path,
                monoSubtitle: true,
                trailing: IconButton(
                  onPressed: () => onShowDerivationInfo(path),
                  tooltip: 'About derivation paths',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: SettingsPalette.textSecondary,
                  ),
                ),
              ),
            GlassRowTile(
              icon: Icons.link_rounded,
              iconColor: SettingsPalette.accent,
              title: 'Connected dApps',
              subtitle: 'Manage Web3 sessions',
              trailing: const GlassChevron(),
              onTap: onConnectedApps,
            ),
          ],
        ),
      ],
    );
  }
}

class _ExplorersSection extends StatelessWidget {
  const _ExplorersSection({
    required this.profile,
    required this.onExplorer,
    required this.onExport,
  });

  final WalletProfile profile;
  final VoidCallback onExplorer;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GlassSectionLabel('Explorers & export'),
        GlassGroupCard(
          children: [
            GlassRowTile(
              icon: Icons.travel_explore_rounded,
              title: 'Etherscan Explorer',
              subtitle: 'etherscan.io/address/${profile.shortAddress}',
              monoSubtitle: true,
              trailing: const _ExternalIcon(),
              onTap: onExplorer,
            ),
            GlassRowTile(
              icon: Icons.public_rounded,
              title: 'Multi-Chain Explorer',
              subtitle: 'Balances across every EVM network',
              trailing: const _ExternalIcon(),
              onTap: onExplorer,
            ),
            GlassRowTile(
              icon: Icons.description_outlined,
              title: 'Export Activity CSV',
              subtitle: 'Download your transaction history',
              trailing: const Icon(
                Icons.download_rounded,
                size: 16,
                color: SettingsPalette.textSecondary,
              ),
              onTap: onExport,
            ),
          ],
        ),
      ],
    );
  }
}

class _ExternalIcon extends StatelessWidget {
  const _ExternalIcon();

  @override
  Widget build(BuildContext context) => const Icon(
        Icons.open_in_new_rounded,
        size: 14,
        color: SettingsPalette.textSecondary,
      );
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GlassSectionLabel(
          'Danger zone',
          color: SettingsPalette.danger,
          icon: Icons.warning_amber_rounded,
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(147, 0, 10, 0.2),
                SettingsPalette.cardMuted,
                SettingsPalette.cardMuted,
              ],
              stops: [0, 0.5, 1],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.25),
                blurRadius: 50,
                spreadRadius: -12,
                offset: Offset(0, 25),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(147, 0, 10, 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_forever_outlined,
                      size: 18,
                      color: SettingsPalette.danger,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remove Wallet from Device',
                          style: TextStyle(
                            color: SettingsPalette.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Erases the secure enclave keys from this phone. '
                          'Make sure you have safely backed up your recovery '
                          'phrase first. Unbacked keys cannot be restored.',
                          style: TextStyle(
                            color: SettingsPalette.textSecondary,
                            fontSize: 12,
                            height: 20 / 12,
                            letterSpacing: 0.12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: Material(
                  color: SettingsPalette.danger,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: onRemove,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: SettingsPalette.dangerOnBadge,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Remove Wallet',
                          style: TextStyle(
                            color: SettingsPalette.dangerOnBadge,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.07,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 40,
            color: SettingsPalette.danger,
          ),
          const SizedBox(height: 12),
          const Text(
            "Couldn't load wallet details",
            style: TextStyle(color: SettingsPalette.textSecondary),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Try Again',
              style: TextStyle(color: SettingsPalette.accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Same gradient chip the Portfolio header uses for the profile, here as the
/// "add wallet" button (create or import another wallet).
class _HeaderAddButton extends StatelessWidget {
  const _HeaderAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add wallet',
      child: InkResponse(
        onTap: onPressed,
        radius: 24,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SettingsPalette.glowPurple, SettingsPalette.accent],
            ),
          ),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              Icons.add_rounded,
              size: 20,
              color: SettingsPalette.background,
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletAmbient extends StatelessWidget {
  const _WalletAmbient();

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: 16,
            child: _Blob(size: 240, color: Color(0xFF5B3E8C), alpha: 0.2, sigma: 27),
          ),
          Positioned(
            left: -48,
            top: 104,
            child: _Blob(
              size: 256,
              color: SettingsPalette.accent,
              alpha: 0.1,
              sigma: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.size,
    required this.color,
    required this.alpha,
    required this.sigma,
  });

  final double size;
  final Color color;
  final double alpha;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: alpha),
        ),
      ),
    );
  }
}
