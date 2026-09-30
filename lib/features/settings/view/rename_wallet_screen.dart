import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../data/wallet_name.dart';
import '../view_model/rename_wallet_cubit.dart';
import '../view_model/rename_wallet_state.dart';
import 'widgets/settings_palette.dart';
import 'widgets/settings_pill_button.dart';
import 'widgets/settings_sub_header.dart';

/// Wallet Details → rename. Pops with the new (trimmed) name once it has been
/// stored, or with nothing if the user cancels.
class RenameWalletScreen extends StatelessWidget {
  const RenameWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RenameWalletCubit, RenameWalletState>(
      listenWhen: (_, next) => next is RenameWalletSaved,
      listener: (context, state) {
        if (state is! RenameWalletSaved) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Wallet renamed')));
        context.pop(state.name);
      },
      builder: (context, state) {
        final ready = state is RenameWalletReady ? state : null;
        return SettingsPageScaffold(
          title: 'Lexor Enclave',
          bottom: ready == null ? null : _Actions(state: ready),
          child: switch (state) {
            RenameWalletLoading() ||
            RenameWalletSaved() =>
              const Center(child: CircularProgressIndicator()),
            RenameWalletFailure() => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Couldn't load your wallet",
                      style: TextStyle(color: SettingsPalette.textSecondary),
                    ),
                    TextButton(
                      onPressed: context.read<RenameWalletCubit>().load,
                      child: const Text(
                        'Try Again',
                        style: TextStyle(color: SettingsPalette.accent),
                      ),
                    ),
                  ],
                ),
              ),
            RenameWalletReady() => _RenameForm(state: state),
          },
        );
      },
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.state});

  final RenameWalletReady state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsPillButton(
            label: 'Save Changes',
            icon: Icons.check_rounded,
            onPressed: state.canSave ? context.read<RenameWalletCubit>().save : null,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: TextButton(
              onPressed: state.saving ? null : () => context.pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: SettingsPalette.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RenameForm extends StatefulWidget {
  const _RenameForm({required this.state});

  final RenameWalletReady state;

  @override
  State<_RenameForm> createState() => _RenameFormState();
}

class _RenameFormState extends State<_RenameForm> {
  // Seeded once from the loaded name; after that the field is the source of
  // truth and the cubit just mirrors it.
  late final _controller = TextEditingController(text: widget.state.draft);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply(String name) {
    _controller.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
    context.read<RenameWalletCubit>().draftChanged(name);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final invalid = !state.isDraftValid;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const Text(
          'VAULT IDENTITY',
          style: TextStyle(
            color: SettingsPalette.accent,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.44,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Rename Wallet',
          style: TextStyle(
            color: SettingsPalette.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Update the personalized moniker for your sovereign ledger '
          'instance.',
          style: TextStyle(
            color: SettingsPalette.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _CurrentNameCard(
          name: state.currentName,
          shortAddress: state.shortAddress,
        ),
        const SizedBox(height: 24),
        const _LabelRow(label: 'WALLET NAME', trailing: 'Editable'),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          autofocus: true,
          enabled: !state.saving,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            LengthLimitingTextInputFormatter(WalletName.maxLength),
          ],
          onChanged: context.read<RenameWalletCubit>().draftChanged,
          onSubmitted: (_) => context.read<RenameWalletCubit>().save(),
          cursorColor: SettingsPalette.accent,
          style: const TextStyle(
            color: SettingsPalette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: SettingsPalette.keyPanel,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: _border(Colors.transparent),
            enabledBorder: _border(
              invalid ? SettingsPalette.danger : Colors.transparent,
            ),
            focusedBorder: _border(
              invalid ? SettingsPalette.danger : SettingsPalette.accent,
            ),
            disabledBorder: _border(Colors.transparent),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                state.saveFailure != null
                    ? "Couldn't save the name. Try again."
                    : 'Must be 1-${WalletName.maxLength} characters',
                style: TextStyle(
                  color: invalid || state.saveFailure != null
                      ? SettingsPalette.danger
                      : SettingsPalette.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              '${state.draftLength} / ${WalletName.maxLength}',
              style: const TextStyle(
                color: SettingsPalette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _LabelRow(label: 'PRESET SUGGESTIONS', trailing: 'Tap to apply'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in WalletName.suggestions)
              _PresetChip(
                label: name,
                selected: WalletName.normalize(state.draft) == name,
                onTap: state.saving ? null : () => _apply(name),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const _StorageNote(),
      ],
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );
}

class _CurrentNameCard extends StatelessWidget {
  const _CurrentNameCard({required this.name, required this.shortAddress});

  final String name;
  final String shortAddress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SettingsPalette.glassCardSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT NAME',
            style: TextStyle(
              color: SettingsPalette.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.44,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SettingsPalette.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            shortAddress,
            style: const TextStyle(
              color: SettingsPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.48,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, required this.trailing});

  final String label;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SettingsPalette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: const TextStyle(
              color: SettingsPalette.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.44,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? SettingsPalette.accent.withValues(alpha: 0.2)
            : SettingsPalette.cardAlt,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? SettingsPalette.accent
                    : SettingsPalette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StorageNote extends StatelessWidget {
  const _StorageNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SettingsPalette.cardMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined,
              size: 20, color: SettingsPalette.accent),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Enclave Storage',
                  style: TextStyle(
                    color: SettingsPalette.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Wallet names are stored locally in your device's secure "
                  'enclave and are never shared with blockchain nodes or '
                  'third parties.',
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
    );
  }
}
