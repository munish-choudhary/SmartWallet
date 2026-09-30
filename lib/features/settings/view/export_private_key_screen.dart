import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/design_system/segmented_toggle.dart';
import '../../../core/result/result.dart';
import '../../../core/security/screen_protection_mixin.dart';
import '../../../core/vault/pin.dart';
import '../data/secret_reveal_gateway.dart';
import 'widgets/pin_gate.dart';
import 'widgets/secret_reveal_body.dart';
import 'widgets/settings_palette.dart';
import 'widgets/settings_sub_header.dart';

enum _KeyView { hex, qr }

class ExportPrivateKeyScreen extends StatefulWidget {
  const ExportPrivateKeyScreen({super.key});

  @override
  State<ExportPrivateKeyScreen> createState() => _ExportPrivateKeyScreenState();
}

class _ExportPrivateKeyScreenState
    extends SecretRevealState<ExportPrivateKeyScreen>
    with ScreenProtectionMixin<ExportPrivateKeyScreen> {
  bool _revealed = false;
  _KeyView _view = _KeyView.hex;
  ExportAccount? _account;

  @override
  Future<bool> submitPin(Pin pin) async {
    final ok = await super.submitPin(pin);
    if (!ok || !mounted) return ok;
    final result = await context.read<SecretRevealGateway>().loadAccount();
    if (mounted) setState(() => _account = result.valueOrNull);
    return ok;
  }

  @override
  Future<Uint8List?> loadSecret(Pin pin) async {
    final result = await context.read<SecretRevealGateway>().revealPrivateKey(pin);
    return result.valueOrNull;
  }

  String get _hex => secretBytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  @override
  Widget build(BuildContext context) {
    final account = _account;
    return SettingsPageScaffold(
      title: 'Export Private Key',
      glow: SettingsPalette.danger,
      child: !isUnlocked
          ? PinGate(
              title: 'Enter your PIN',
              subtitle: 'Your PIN is always required to export a private key.',
              onSubmit: submitPin,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const ShieldBadge(label: 'SCREENSHOTS & RECORDING BLOCKED'),
                const SizedBox(height: 16),
                DangerCard(
                  title: 'EXTREME CAUTION',
                  badge: 'NEVER EXPOSE',
                  message: 'Your private key grants unrestricted, irrevocable '
                      'access to this account on ${account?.network ?? 'this'} '
                      'network. Anyone who views it can drain all your assets '
                      'instantly.',
                ),
                const SizedBox(height: 16),
                if (account != null) ...[
                  _AccountCard(account: account),
                  const SizedBox(height: 16),
                ],
                _KeyModule(
                  view: _view,
                  onViewChanged: (v) => setState(() => _view = v),
                  revealed: _revealed,
                  hex: _revealed ? _hex : '',
                  onToggleReveal: () => setState(() => _revealed = !_revealed),
                  onCopy: _revealed ? () => copySecret(context, _hex) : null,
                ),
                const SizedBox(height: 16),
                const ProtocolsCard(
                  title: 'SECURITY PROTOCOLS',
                  items: [
                    (
                      Icons.verified_user_outlined,
                      SettingsPalette.accent,
                      'This key is stored purely on-chip in the device '
                          'hardware enclave. Lexor Pocket servers never '
                          'transmit or retain it.',
                    ),
                    (
                      Icons.error_outline_rounded,
                      SettingsPalette.danger,
                      'Never paste this key into any website, Telegram bot, '
                          'or support form. Support staff will never request '
                          'it.',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsSecondaryButton(
                  label: 'Done & Lock Key',
                  icon: Icons.lock_rounded,
                  color: SettingsPalette.danger,
                  onPressed: () {
                    wipe();
                    Navigator.of(context).maybePop();
                  },
                ),
              ],
            ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});
  final ExportAccount account;

  @override
  Widget build(BuildContext context) {
    final a = account.address;
    final short = '${a.substring(0, 6)}...${a.substring(a.length - 4)}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SettingsPalette.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: SettingsPalette.chip,
            child: Icon(Icons.account_balance_wallet_rounded,
                color: SettingsPalette.textPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(
                    color: SettingsPalette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  short,
                  style: const TextStyle(
                    color: SettingsPalette.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: SettingsPalette.chip,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              account.network,
              style: const TextStyle(
                color: SettingsPalette.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyModule extends StatelessWidget {
  const _KeyModule({
    required this.view,
    required this.onViewChanged,
    required this.revealed,
    required this.hex,
    required this.onToggleReveal,
    required this.onCopy,
  });

  final _KeyView view;
  final ValueChanged<_KeyView> onViewChanged;
  final bool revealed;
  final String hex;
  final VoidCallback onToggleReveal;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(27, 27, 31, 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SegmentedToggle<_KeyView>(
            options: const [(_KeyView.hex, 'Hex Key'), (_KeyView.qr, 'QR Code')],
            selected: view,
            onChanged: onViewChanged,
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(minHeight: 160),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SettingsPalette.keyPanel.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (view == _KeyView.qr)
                  _QrView(revealed: revealed, data: hex)
                else
                  _HexText(hex: revealed ? hex : '0' * 64, blurred: !revealed),
                const SizedBox(height: 12),
                SettingsSecondaryButton(
                  label: revealed ? 'Hide Secret Key' : 'Tap to Reveal Secret Key',
                  icon: revealed
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: SettingsPalette.accent,
                  expand: false,
                  onPressed: onToggleReveal,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ensure no cameras or onlookers are nearby',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SettingsPalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SettingsSecondaryButton(
            label: 'Copy Private Key',
            icon: Icons.copy_rounded,
            onPressed: onCopy,
          ),
          const SizedBox(height: 8),
          const Text(
            'Clipboard is purged automatically after 60s',
            style: TextStyle(color: SettingsPalette.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QrView extends StatelessWidget {
  const _QrView({required this.revealed, required this.data});
  final bool revealed;
  final String data;

  @override
  Widget build(BuildContext context) {
    if (!revealed) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 48, color: SettingsPalette.textSecondary),
          SizedBox(height: 8),
          Text(
            'Tap to Reveal to show the QR code',
            style: TextStyle(color: SettingsPalette.textSecondary),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: QrImageView(
        data: data,
        size: 200,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );
  }
}

class _HexText extends StatelessWidget {
  const _HexText({required this.hex, required this.blurred});
  final String hex;
  final bool blurred;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      hex,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: SettingsPalette.accent,
        fontSize: 13,
        height: 1.6,
        letterSpacing: 0.65,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
    if (!blurred) return text;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: text,
    );
  }
}
