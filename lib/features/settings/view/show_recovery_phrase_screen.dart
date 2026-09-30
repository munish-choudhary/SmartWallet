import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../../../core/security/screen_protection_mixin.dart';
import '../../../core/vault/pin.dart';
import '../data/secret_reveal_gateway.dart';
import 'widgets/pin_gate.dart';
import 'widgets/secret_reveal_body.dart';
import 'widgets/settings_palette.dart';
import 'widgets/settings_pill_button.dart';
import 'widgets/settings_sub_header.dart';

class ShowRecoveryPhraseScreen extends StatefulWidget {
  const ShowRecoveryPhraseScreen({super.key});

  @override
  State<ShowRecoveryPhraseScreen> createState() =>
      _ShowRecoveryPhraseScreenState();
}

class _ShowRecoveryPhraseScreenState
    extends SecretRevealState<ShowRecoveryPhraseScreen>
    with ScreenProtectionMixin<ShowRecoveryPhraseScreen> {
  // Press-and-hold to reveal; releasing hides instantly.
  bool _holding = false;

  @override
  Future<Uint8List?> loadSecret(Pin pin) async {
    final result =
        await context.read<SecretRevealGateway>().revealRecoveryPhrase(pin);
    return result.valueOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'Backup Recovery',
      glow: SettingsPalette.danger,
      child: !isUnlocked
          ? PinGate(
              title: 'Enter your PIN',
              subtitle:
                  'Your PIN is always required to view your recovery phrase.',
              onSubmit: submitPin,
            )
          : _buildPhrase(context),
    );
  }

  Widget _buildPhrase(BuildContext context) {
    final phrase = utf8.decode(secretBytes);
    final words = phrase.split(' ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        DangerCard(
          title: 'Never share your Recovery Phrase',
          message: 'Anyone with these ${words.length} words can permanently '
              'control all your digital assets. Lexor Pocket staff will never '
              'ask for your phrase.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(27, 27, 31, 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Tag(Icons.circle, 'BIP-39 ENCRYPTED • 128-BIT SEED'),
                  _Tag(Icons.lock_outline_rounded, 'Air-Gapped Vault'),
                ],
              ),
              const SizedBox(height: 12),
              _PhraseGrid(words: words, blurred: !_holding),
              const SizedBox(height: 16),
              Listener(
                onPointerDown: (_) => setState(() => _holding = true),
                onPointerUp: (_) => setState(() => _holding = false),
                onPointerCancel: (_) => setState(() => _holding = false),
                child: const SettingsSecondaryButton(
                  label: 'Hold to Reveal Phrase',
                  icon: Icons.visibility_outlined,
                  color: SettingsPalette.accent,
                  expand: false,
                  onPressed: _noop,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Release anytime to hide instantly',
                style: TextStyle(
                  color: SettingsPalette.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: SettingsSecondaryButton(
            label: 'Copy to Secure Clipboard',
            icon: Icons.copy_rounded,
            expand: false,
            onPressed: () => copySecret(context, phrase),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Clipboard auto-clears in 60s to prevent hijacking.',
          textAlign: TextAlign.center,
          style: TextStyle(color: SettingsPalette.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),
        const ProtocolsCard(
          title: 'Storage Protocols',
          items: [
            (
              Icons.circle,
              SettingsPalette.accent,
              'Write down these words on physical paper or stamp on cold '
                  'steel; store in a waterproof, fire-resistant lockbox.',
            ),
            (
              Icons.circle,
              SettingsPalette.danger,
              'Never take screenshots, photographs, or store in cloud notes '
                  'or digital messaging services.',
            ),
            (
              Icons.circle,
              SettingsPalette.textSecondary,
              'Lexor Enclave uses non-custodial zero-knowledge storage; loss '
                  'of phrase is irreversible.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsPillButton(
          label: 'I Have Backed It Up',
          icon: Icons.arrow_forward_rounded,
          onPressed: () {
            wipe();
            Navigator.of(context).maybePop();
          },
        ),
      ],
    );
  }
}

void _noop() {}

class _Tag extends StatelessWidget {
  const _Tag(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Flexible(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: SettingsPalette.accent),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SettingsPalette.textSecondary,
                  fontSize: 10,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      );
}

class _PhraseGrid extends StatelessWidget {
  const _PhraseGrid({required this.words, required this.blurred});
  final List<String> words;
  final bool blurred;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 4.2,
      children: [
        for (var i = 0; i < words.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: SettingsPalette.keyPanel.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  '${i + 1}'.padLeft(2, '0'),
                  style: const TextStyle(
                    color: SettingsPalette.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    blurred ? '••••••' : words[i],
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SettingsPalette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
