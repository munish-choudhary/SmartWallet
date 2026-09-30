import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auto_lock_option.dart';
import '../view_model/auto_lock_cubit.dart';
import '../view_model/auto_lock_state.dart';
import 'widgets/settings_palette.dart';
import 'widgets/settings_pill_button.dart';
import 'widgets/settings_sub_header.dart';

class AutoLockTimerScreen extends StatelessWidget {
  const AutoLockTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AutoLockCubit, AutoLockState>(
      listenWhen: (a, b) => b is AutoLockReady && b.justSaved,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auto-lock updated')),
        );
      },
      builder: (context, state) {
        final ready = state is AutoLockReady ? state : null;
        return SettingsPageScaffold(
          title: 'Auto-Lock Timer',
          bottom: ready == null
              ? null
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SettingsPillButton(
                        label: 'Save Changes',
                        icon: Icons.check_rounded,
                        onPressed: ready.selected == ready.saved || ready.saving
                            ? null
                            : context.read<AutoLockCubit>().save,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'APPLIES WHEN THE APP IS IN THE BACKGROUND',
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
          child: switch (state) {
            AutoLockLoading() =>
              const Center(child: CircularProgressIndicator()),
            AutoLockFailure() => const Center(
                child: Text(
                  "Couldn't load settings",
                  style: TextStyle(color: SettingsPalette.textSecondary),
                ),
              ),
            AutoLockReady() => _Body(state: state),
          },
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});
  final AutoLockReady state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: SettingsPalette.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: SettingsPalette.chip,
                child: Icon(Icons.lock_clock_rounded,
                    color: SettingsPalette.accent),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Choose how long Lexor Pocket stays unlocked after you '
                  'leave the app. Shorter times keep your assets safer if '
                  'your phone is lost or borrowed.',
                  style: TextStyle(
                    color: SettingsPalette.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final option in AutoLockOption.values) ...[
          _OptionTile(
            option: option,
            selected: option == state.selected,
            onTap: () => context.read<AutoLockCubit>().select(option),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SettingsPalette.cardMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.security_rounded,
                  size: 18, color: SettingsPalette.accent),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secure Enclave Protection',
                      style: TextStyle(
                        color: SettingsPalette.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'When the timer expires, the in-memory session key is '
                      'wiped. Your PIN or biometrics are needed to unlock '
                      'again.',
                      style: TextStyle(
                        color: SettingsPalette.textSecondary,
                        fontSize: 12,
                        height: 1.6,
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AutoLockOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final risky = option == AutoLockOption.never;
    final recommended = option == AutoLockOption.oneMinute;
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: Material(
        color: selected ? SettingsPalette.cardAlt : SettingsPalette.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? SettingsPalette.accent.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      selected ? SettingsPalette.accent : SettingsPalette.cardAlt,
                  child: Icon(
                    risky ? Icons.warning_amber_rounded : Icons.timer_outlined,
                    size: 18,
                    color: selected
                        ? SettingsPalette.onAccent
                        : risky
                            ? SettingsPalette.danger
                            : SettingsPalette.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              option.label,
                              style: const TextStyle(
                                color: SettingsPalette.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (recommended) ...[
                            const SizedBox(width: 8),
                            const _Badge(
                              'DEFAULT',
                              SettingsPalette.accent,
                              SettingsPalette.onAccent,
                            ),
                          ],
                          if (risky) ...[
                            const SizedBox(width: 8),
                            const _Badge(
                              'RISKY',
                              SettingsPalette.dangerBadge,
                              SettingsPalette.dangerText,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.description,
                        style: const TextStyle(
                          color: SettingsPalette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: selected
                      ? SettingsPalette.accent
                      : SettingsPalette.chip,
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: SettingsPalette.onAccent)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.background, this.foreground);
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: foreground,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
