import 'package:flutter/material.dart';

import '../../../portfolio/data/models/portfolio_snapshot.dart';
import '../../data/wallet_profile.dart';
import 'settings_palette.dart';
import 'wallet_avatar.dart';

/// Hero card of Wallet Details: status, identicon, name (tap to rename),
/// address with copy/QR actions, and the total vault value.
class WalletIdentityCard extends StatelessWidget {
  const WalletIdentityCard({
    super.key,
    required this.profile,
    required this.portfolio,
    required this.onRename,
    required this.onCopyAddress,
    required this.onShowQr,
  });

  final WalletProfile profile;

  /// `null` while the balance is unavailable.
  final PortfolioSnapshot? portfolio;
  final VoidCallback onRename;
  final VoidCallback onCopyAddress;
  final VoidCallback onShowQr;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: SettingsPalette.glassCard,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          const _StatusPill(),
          const SizedBox(height: 16),
          WalletAvatar(seed: profile.address, onEdit: onRename),
          const SizedBox(height: 16),
          _NameRow(name: profile.name, onTap: onRename),
          const SizedBox(height: 8),
          _AddressPill(
            address: profile.shortAddress,
            onCopy: onCopyAddress,
            onShowQr: onShowQr,
          ),
          const SizedBox(height: 24),
          _ValueBlock(portfolio: portfolio),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SettingsPalette.glassChip,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SettingsPalette.accent,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(212, 238, 107, 0.8),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SizedBox(width: 8, height: 8),
          ),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              'HARDWARE VAULT • ACTIVE',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SettingsPalette.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.275,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Rename wallet, currently $name',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SettingsPalette.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 32 / 24,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.edit_outlined,
                size: 15,
                color: SettingsPalette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressPill extends StatelessWidget {
  const _AddressPill({
    required this.address,
    required this.onCopy,
    required this.onShowQr,
  });

  final String address;
  final VoidCallback onCopy;
  final VoidCallback onShowQr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
      decoration: BoxDecoration(
        color: SettingsPalette.keyPanel.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              address,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SettingsPalette.iconMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 14 / 11,
                letterSpacing: 0.55,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PillAction(
            onTap: onCopy,
            semanticLabel: 'Copy address',
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy_rounded, size: 11, color: SettingsPalette.accent),
                SizedBox(width: 2),
                Text(
                  'COPY',
                  style: TextStyle(
                    color: SettingsPalette.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 14 / 11,
                    letterSpacing: 0.44,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          _PillAction(
            onTap: onShowQr,
            semanticLabel: 'Show QR code',
            child: const Icon(
              Icons.qr_code_2_rounded,
              size: 14,
              color: SettingsPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  const _PillAction({
    required this.onTap,
    required this.semanticLabel,
    required this.child,
  });

  final VoidCallback onTap;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: SettingsPalette.cardAlt,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock({required this.portfolio});

  final PortfolioSnapshot? portfolio;

  @override
  Widget build(BuildContext context) {
    final snapshot = portfolio;
    return Column(
      children: [
        const Text(
          'TOTAL VAULT VALUE',
          style: TextStyle(
            color: SettingsPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 16 / 12,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                snapshot?.formattedTotalBalance ?? '—',
                style: const TextStyle(
                  color: SettingsPalette.textPrimary,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 48 / 40,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'USD',
                style: TextStyle(
                  color: SettingsPalette.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.44,
                ),
              ),
            ],
          ),
        ),
        if (snapshot != null) ...[
          const SizedBox(height: 8),
          _ChangePill(snapshot: snapshot),
        ],
      ],
    );
  }
}

class _ChangePill extends StatelessWidget {
  const _ChangePill({required this.snapshot});

  final PortfolioSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final color = snapshot.isPositiveChange
        ? SettingsPalette.accent
        : SettingsPalette.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            snapshot.isPositiveChange
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            snapshot.formattedChangePercent,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 14 / 11,
              letterSpacing: 0.44,
            ),
          ),
        ],
      ),
    );
  }
}
