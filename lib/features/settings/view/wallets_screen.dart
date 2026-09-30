import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/wallet_profile.dart';
import '../view_model/wallets_cubit.dart';
import '../view_model/wallets_state.dart';
import 'add_wallet_launcher.dart';
import 'widgets/settings_palette.dart';
import 'widgets/settings_pill_button.dart';
import 'widgets/settings_sub_header.dart';
import 'widgets/wallet_avatar.dart';

/// Every wallet on the device: tap one to make it the active wallet, or add
/// another (create / import).
class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  Future<void> _select(BuildContext context, WalletProfile wallet) async {
    final switched = await context.read<WalletsCubit>().select(wallet.walletId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            switched
                ? 'Switched to ${wallet.name}'
                : "Couldn't switch wallets",
          ),
        ),
      );
  }

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<WalletsCubit>();
    await startAddWallet(context);
    if (!cubit.isClosed) await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'Wallets',
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SettingsPillButton(
          label: 'Add Wallet',
          icon: Icons.add_rounded,
          onPressed: () => _add(context),
        ),
      ),
      child: BlocBuilder<WalletsCubit, WalletsState>(
        builder: (context, state) => switch (state) {
          WalletsLoading() => const Center(child: CircularProgressIndicator()),
          WalletsFailure() => _LoadFailure(
              onRetry: context.read<WalletsCubit>().load,
            ),
          WalletsLoaded(:final wallets, :final activeId, :final switchingTo) =>
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: wallets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final wallet = wallets[i];
                return _WalletTile(
                  wallet: wallet,
                  active: wallet.walletId == activeId,
                  switching: wallet.walletId == switchingTo,
                  onTap: switchingTo == null
                      ? () => _select(context, wallet)
                      : null,
                );
              },
            ),
        },
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.wallet,
    required this.active,
    required this.switching,
    required this.onTap,
  });

  final WalletProfile wallet;
  final bool active;
  final bool switching;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: '${wallet.name}, ${wallet.shortAddress}'
          '${active ? ', active' : ''}',
      child: Material(
        color: SettingsPalette.glassCardSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: active
                ? SettingsPalette.accent.withValues(alpha: 0.6)
                : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                WalletAvatar(seed: wallet.address, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SettingsPalette.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        wallet.shortAddress,
                        style: const TextStyle(
                          color: SettingsPalette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.44,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (switching)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (active)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 22,
                    color: SettingsPalette.accent,
                  )
                else
                  const Icon(
                    Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color: SettingsPalette.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
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
            "Couldn't load your wallets",
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
