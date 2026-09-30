import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design_system/lexor_page_scaffold.dart';
import '../../../core/design_system/lexor_palette.dart';
import '../../../core/design_system/lexor_primary_button.dart';
import '../../../core/result/result.dart';
import '../../../core/security/screen_protection_mixin.dart';
import '../../../core/vault/vault.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'discard_wallet_dialog.dart';

class RecoveryPhraseScreen extends StatefulWidget {
  const RecoveryPhraseScreen({super.key});

  @override
  State<RecoveryPhraseScreen> createState() => RecoveryPhraseScreenState();
}

/// Not private — a widget test asserts words are cleared on dispose via a
/// `GlobalKey<RecoveryPhraseScreenState>` and [wordsForTest].
class RecoveryPhraseScreenState extends State<RecoveryPhraseScreen>
    with ScreenProtectionMixin<RecoveryPhraseScreen> {
  // Local widget state only — per this feature's security spec, the
  // phrase must never enter Cubit/Bloc state. Cleared in dispose().
  List<String>? _words;
  bool _loading = true;
  bool _revealed = false;

  @visibleForTesting
  List<String>? get wordsForTest => _words;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await context.read<Vault>().pendingPhraseForDisplay();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _words = result.valueOrNull;
    });
  }

  Future<void> _copyToClipboard(List<String> words) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: words.join(' ')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.recoveryPhraseCopiedSnackbar)),
    );
    unawaited(
      Future.delayed(
        const Duration(seconds: 60),
        () => Clipboard.setData(const ClipboardData(text: '')),
      ),
    );
  }

  Future<void> _handleBack() async {
    final left = await confirmDiscardPendingWallet(context);
    if (left && mounted) context.go(Routes.backupWarning);
  }

  @override
  void dispose() {
    _words = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final words = _words;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: LexorPageScaffold(
        title: l10n.recoveryPhraseTitle,
        onBack: _handleBack,
        scrollable: true,
        bottom: words == null
            ? null
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: LexorPrimaryButton(
                  label: l10n.recoveryPhraseSaved,
                  icon: Icons.arrow_forward,
                  onPressed: () => context.push(Routes.verifyPhrase),
                ),
              ),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.only(top: 96),
                child: Center(child: CircularProgressIndicator()),
              )
            : words == null
            ? Center(child: Text(l10n.recoveryPhraseTitle))
            : _PhraseBody(
                words: words,
                revealed: _revealed,
                onToggleReveal: () => setState(() => _revealed = !_revealed),
                onCopy: () => _copyToClipboard(words),
              ),
      ),
    );
  }
}

class _PhraseBody extends StatelessWidget {
  const _PhraseBody({
    required this.words,
    required this.revealed,
    required this.onToggleReveal,
    required this.onCopy,
  });

  final List<String> words;
  final bool revealed;
  final VoidCallback onToggleReveal;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepTracker(label: l10n.recoveryPhraseStepPill),
        const SizedBox(height: 24),
        Text(
          l10n.recoveryPhraseHeadline,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            height: 32 / 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.recoveryPhraseSubtitle(words.length),
          style: const TextStyle(
            color: Color(0xFFC6C6C7),
            fontSize: 14,
            height: 20 / 14,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(27, 27, 31, 0.7),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(14, 14, 18, 0.8),
                blurRadius: 25,
                offset: Offset(0, 20),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: LexorPalette.accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.recoveryPhrasePrivacyLabel.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LexorPalette.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PillAction(
                    icon: revealed
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    label: revealed
                        ? l10n.recoveryPhraseHide
                        : l10n.recoveryPhraseReveal,
                    accentIcon: true,
                    onTap: onToggleReveal,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(31, 31, 35, 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: Color(0xFFC6C6C7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.recoveryPhraseScreenWarning,
                        style: const TextStyle(
                          color: Color(0xFFC6C6C7),
                          fontSize: 12,
                          height: 16 / 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < words.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _WordTile(
                        index: i + 1,
                        word: words[i],
                        hidden: !revealed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: i + 1 < words.length
                          ? _WordTile(
                              index: i + 2,
                              word: words[i + 1],
                              hidden: !revealed,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Opacity(
          opacity: revealed ? 1 : 0.5,
          child: _PillAction(
            icon: Icons.copy_outlined,
            label: l10n.recoveryPhraseCopy,
            expanded: true,
            onTap: revealed ? onCopy : null,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: LexorPalette.sheet,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF353439),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.no_photography_outlined,
                  size: 16,
                  color: LexorPalette.danger,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.recoveryPhraseScreenshotWarningTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 16 / 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.recoveryPhraseScreenshotWarningBody,
                      style: const TextStyle(
                        color: Color(0xFFC6C6C7),
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Step 2 of 3" pill on the left, three progress bars on the right.
class _StepTracker extends StatelessWidget {
  const _StepTracker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(42, 41, 46, 0.8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: LexorPalette.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: LexorPalette.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.55,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: i < 2
                      ? LexorPalette.accent
                      : const Color(0xFF353439),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PillAction extends StatelessWidget {
  const _PillAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accentIcon = false,
    this.expanded = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool accentIcon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final small = accentIcon;
    return Material(
      color: const Color.fromRGBO(42, 41, 46, 0.9),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: small ? 12 : 16,
            vertical: small ? 6 : 15,
          ),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: small ? 14 : 15,
                color: accentIcon ? LexorPalette.accent : Colors.white,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  small ? label.toUpperCase() : label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LexorPalette.textPrimary,
                    fontSize: small ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: small ? 0.44 : 0.24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.index,
    required this.word,
    required this.hidden,
  });

  final int index;
  final String word;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    // Hidden words are masked with dots rather than blurred, so the text
    // is never in the tree (keeps it out of semantics and `find.text`).
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(14, 14, 18, 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            index.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Color.fromRGBO(212, 238, 107, 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.44,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hidden ? '•' * word.length.clamp(3, 8) : word,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              semanticsLabel: hidden ? 'hidden word' : null,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
