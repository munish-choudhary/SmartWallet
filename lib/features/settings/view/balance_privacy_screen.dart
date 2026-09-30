import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../view_model/balance_privacy_cubit.dart';
import '../view_model/balance_privacy_state.dart';
import 'widgets/settings_palette.dart';
import 'widgets/settings_sub_header.dart';

class BalancePrivacyScreen extends StatelessWidget {
  const BalancePrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'Balance Privacy',
      child: BlocBuilder<BalancePrivacyCubit, BalancePrivacyState>(
        builder: (context, state) => switch (state) {
          BalancePrivacyLoading() =>
            const Center(child: CircularProgressIndicator()),
          BalancePrivacyFailure() => const Center(
              child: Text(
                "Couldn't load settings",
                style: TextStyle(color: SettingsPalette.textSecondary),
              ),
            ),
          BalancePrivacyReady(:final hideBalances) =>
            _Body(hideBalances: hideBalances),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.hideBalances});
  final bool hideBalances;

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
                child: Icon(Icons.visibility_off_outlined,
                    color: SettingsPalette.accent),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Mask balances and monetary figures when the app opens, '
                  'so nobody nearby can read them over your shoulder.',
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
        Container(
          decoration: BoxDecoration(
            color: SettingsPalette.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            value: hideBalances,
            onChanged: context.read<BalancePrivacyCubit>().setHideBalances,
            activeThumbColor: SettingsPalette.onAccent,
            activeTrackColor: SettingsPalette.accent,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: const Text(
              'Hide Balances on Launch',
              style: TextStyle(
                color: SettingsPalette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Shows •••• instead of amounts until you reveal them',
              style: TextStyle(
                color: SettingsPalette.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
