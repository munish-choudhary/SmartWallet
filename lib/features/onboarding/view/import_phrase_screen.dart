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
import '../../../core/design_system/segmented_toggle.dart';
import '../../../core/design_system/word_chip.dart';
import '../../../core/security/screen_protection_mixin.dart';
import '../../../core/vault/vault.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/bip39_wordlist.dart';
import '../data/onboarding_import_holder.dart';
import 'pin_entry_navigation.dart';
import '../view_model/import_phrase_cubit.dart';

class ImportPhraseScreen extends StatelessWidget {
  const ImportPhraseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ImportPhraseCubit(
        vault: context.read<Vault>(),
        wordlist: context.read<Bip39Wordlist>(),
      ),
      child: const _ImportPhraseView(),
    );
  }
}

class _ImportPhraseView extends StatefulWidget {
  const _ImportPhraseView();

  @override
  State<_ImportPhraseView> createState() => _ImportPhraseViewState();
}

class _ImportPhraseViewState extends State<_ImportPhraseView>
    with ScreenProtectionMixin<_ImportPhraseView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applySuggestion(ImportPhraseCubit cubit, String suggestion) {
    final words = [...cubit.state.words];
    final lastNonEmpty = words.lastIndexWhere((w) => w.isNotEmpty);
    if (lastNonEmpty == -1) return;
    words[lastNonEmpty] = suggestion;
    final text = words.where((w) => w.isNotEmpty).join(' ');
    _controller.value = TextEditingValue(
      text: '$text ',
      selection: TextSelection.collapsed(offset: text.length + 1),
    );
    cubit.pasteAll(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OnboardingScaffold(
      onBack: () => context.pop(),
      body: BlocBuilder<ImportPhraseCubit, ImportPhraseState>(
        builder: (context, state) {
          final cubit = context.read<ImportPhraseCubit>();
          final suggestions = state.words.isEmpty
              ? const <String>[]
              : cubit.suggestionsFor(state.words.lastIndexWhere((w) => w.isNotEmpty));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.importPhraseTitle,
                textAlign: TextAlign.center,
                style: AppTypography.headline,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.importPhraseSubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.xl),
              SegmentedToggle<int>(
                options: [
                  (12, l10n.importPhrase12Words),
                  (24, l10n.importPhrase24Words),
                ],
                selected: state.wordCount,
                onChanged: (count) {
                  _controller.clear();
                  cubit.setWordCount(count);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: 3,
                      minLines: 2,
                      style: AppTypography.bodyStrong,
                      enableSuggestions: false,
                      autocorrect: false,
                      enableIMEPersonalizedLearning: false,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      onChanged: cubit.pasteAll,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final data = await Clipboard.getData(
                              Clipboard.kTextPlain,
                            );
                            final text = data?.text;
                            if (text == null) return;
                            _controller.text = text;
                            cubit.pasteAll(text);
                          },
                          icon: const Icon(Icons.paste, size: 16),
                          label: Text(l10n.importPhrasePasteAll),
                        ),
                        TextButton(
                          onPressed: () {
                            _controller.clear();
                            cubit.clear();
                          },
                          child: Text(l10n.importPhraseClear),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    for (final s in suggestions)
                      ActionChip(
                        label: Text(s),
                        onPressed: () => _applySuggestion(cubit, s),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var i = 0; i < state.words.length; i++)
                    if (state.words[i].isNotEmpty)
                      WordChip(
                        word: state.words[i],
                        index: i + 1,
                        state: state.invalidIndices.contains(i)
                            ? WordChipState.incorrect
                            : WordChipState.normal,
                      ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.importPhraseWordsValid(
                  [
                    for (var i = 0; i < state.words.length; i++)
                      if (state.words[i].isNotEmpty &&
                          !state.invalidIndices.contains(i))
                        i,
                  ].length,
                  state.wordCount,
                ),
                style: AppTypography.label.copyWith(color: AppColors.accent),
              ),
              if (state.checksumValid) ...[
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  borderColor: AppColors.accent,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.importPhraseChecksumValid,
                              style: AppTypography.bodyStrong,
                            ),
                            Text(
                              l10n.importPhraseChecksumValidBody,
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
      footer: BlocBuilder<ImportPhraseCubit, ImportPhraseState>(
        builder: (context, state) {
          return PillButton(
            label: l10n.importWallet,
            icon: Icons.arrow_forward,
            onPressed: state.checksumValid
                ? () {
                    context.read<OnboardingImportHolder>().storeMnemonic(
                      context.read<ImportPhraseCubit>().joinedMnemonic,
                    );
                    context.pushPinEntry();
                  }
                : null,
          );
        },
      ),
    );
  }
}
