import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/result/result.dart';
import '../data/network_draft.dart';
import '../data/network_preset.dart';
import '../view_model/add_custom_network_cubit.dart';
import '../view_model/add_custom_network_state.dart';
import 'widgets/network_field_card.dart';
import 'widgets/network_preset_chips.dart';
import 'widgets/rpc_ping_indicator.dart';
import 'widgets/settings_palette.dart';
import 'widgets/settings_sub_header.dart';

/// Settings → Networks → Add Custom Network.
///
/// Text lives in the controllers; the Cubit holds the same values as its
/// source of truth and pushes them back only when a preset fills the form.
class AddCustomNetworkScreen extends StatefulWidget {
  const AddCustomNetworkScreen({super.key});

  @override
  State<AddCustomNetworkScreen> createState() => _AddCustomNetworkScreenState();
}

class _AddCustomNetworkScreenState extends State<AddCustomNetworkScreen> {
  final _name = TextEditingController();
  final _rpcUrl = TextEditingController();
  final _chainId = TextEditingController();
  final _symbol = TextEditingController();
  final _explorerUrl = TextEditingController();
  final _rpcFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _rpcFocus.addListener(_onRpcFocusChanged);
  }

  @override
  void dispose() {
    _rpcFocus
      ..removeListener(_onRpcFocusChanged)
      ..dispose();
    _name.dispose();
    _rpcUrl.dispose();
    _chainId.dispose();
    _symbol.dispose();
    _explorerUrl.dispose();
    super.dispose();
  }

  /// Leaving the RPC field tests the endpoint (once per URL).
  void _onRpcFocusChanged() {
    if (!_rpcFocus.hasFocus) context.read<AddCustomNetworkCubit>().checkRpc();
  }

  void _fillFrom(NetworkDraft draft) {
    _name.text = draft.name;
    _rpcUrl.text = draft.rpcUrl;
    _chainId.text = draft.chainId;
    _symbol.text = draft.symbol;
    _explorerUrl.text = draft.explorerUrl;
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.portfolio);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AddCustomNetworkCubit, AddCustomNetworkState>(
          listenWhen: (prev, curr) =>
              curr is AddNetworkEditing &&
              curr.preset != null &&
              (prev is! AddNetworkEditing || prev.preset != curr.preset),
          listener: (context, state) =>
              _fillFrom((state as AddNetworkEditing).draft),
        ),
        BlocListener<AddCustomNetworkCubit, AddCustomNetworkState>(
          listenWhen: (prev, curr) => curr is AddNetworkSaved,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${(state as AddNetworkSaved).network.name} added'),
              ),
            );
            _close();
          },
        ),
      ],
      child: SettingsPageScaffold(
        title: 'Add Custom Network',
        ambient: const _NetworkAmbient(),
        child: BlocBuilder<AddCustomNetworkCubit, AddCustomNetworkState>(
          builder: (context, state) => switch (state) {
            AddNetworkEditing() => _buildForm(context, state),
            // Saved: the screen is closing.
            AddNetworkSaved() => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AddNetworkEditing s) {
    final cubit = context.read<AddCustomNetworkCubit>();
    final saving = s.save is SaveInProgress;
    final chainNote = _chainIdNote(s);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 4, bottom: 32),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _IntroHeader(),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _PresetsLabel(),
        ),
        const SizedBox(height: 4),
        NetworkPresetChips(
          presets: NetworkPreset.all,
          selected: s.preset,
          enabled: !saving,
          onSelected: cubit.selectPreset,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NetworkFieldCard(
                icon: Icons.label_outline_rounded,
                label: 'Network Name',
                labelTrailing: _NamePill(isPreset: s.preset != null),
                errorText: _fieldError(s, NetworkField.name),
                child: Row(
                  children: [
                    Expanded(
                      child: NetworkTextInput(
                        controller: _name,
                        hint: 'e.g. Ethereum Fast Relay',
                        enabled: !saving,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        onChanged: cubit.nameChanged,
                      ),
                    ),
                    if (s.draft.name.isNotEmpty && !saving)
                      _InlineIconButton(
                        icon: Icons.close_rounded,
                        color: SettingsPalette.textSecondary,
                        tooltip: 'Clear name',
                        onPressed: () {
                          _name.clear();
                          cubit.nameChanged('');
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              NetworkFieldCard(
                icon: Icons.lan_outlined,
                label: 'RPC URL',
                labelTrailing: RpcPingPill(check: s.rpc),
                errorText: _fieldError(s, NetworkField.rpcUrl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: NetworkTextInput(
                            controller: _rpcUrl,
                            focusNode: _rpcFocus,
                            hint: 'https://',
                            style: NetworkTextInput.url,
                            enabled: !saving,
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                            onChanged: cubit.rpcUrlChanged,
                          ),
                        ),
                        _InlineIconButton(
                          icon: Icons.refresh_rounded,
                          color: SettingsPalette.accent,
                          tooltip: 'Test connection',
                          onPressed: saving || s.rpc is RpcChecking
                              ? null
                              : () => cubit.checkRpc(force: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RpcLatencyBar(check: s.rpc),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: NetworkFieldCard(
                        icon: Icons.tag_rounded,
                        label: 'Chain ID',
                        errorText: _fieldError(s, NetworkField.chainId),
                        footer: chainNote,
                        child: Row(
                          children: [
                            Expanded(
                              child: NetworkTextInput(
                                controller: _chainId,
                                hint: '1',
                                style: NetworkTextInput.value,
                                enabled: !saving,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(16),
                                ],
                                onChanged: cubit.chainIdChanged,
                              ),
                            ),
                            if (s.chainIdCheck == ChainIdCheck.matches)
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: SettingsPalette.accent,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: NetworkFieldCard(
                        icon: Icons.toll_outlined,
                        label: 'Symbol',
                        errorText: _fieldError(s, NetworkField.symbol),
                        footer: const NetworkFieldNote(
                          text: 'Gas accounting token',
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: NetworkTextInput(
                                controller: _symbol,
                                hint: 'ETH',
                                style: NetworkTextInput.value,
                                enabled: !saving,
                                textInputAction: TextInputAction.next,
                                textCapitalization:
                                    TextCapitalization.characters,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp('[A-Za-z0-9]'),
                                  ),
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                onChanged: cubit.symbolChanged,
                              ),
                            ),
                            const _GasChip(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              NetworkFieldCard(
                icon: Icons.travel_explore_rounded,
                label: 'Block Explorer',
                labelTrailing: const Text(
                  'OPTIONAL',
                  style: TextStyle(
                    color: Color(0x99C6C8B2),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.07,
                  ),
                ),
                errorText: _fieldError(s, NetworkField.explorerUrl),
                child: NetworkTextInput(
                  controller: _explorerUrl,
                  hint: 'https://',
                  style: NetworkTextInput.url,
                  enabled: !saving,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onChanged: cubit.explorerUrlChanged,
                  onSubmitted: (_) => cubit.submit(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 18),
                child: _SecurityWarning(),
              ),
              if (s.save case SaveFailed(:final failure))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _saveFailureMessage(failure),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: SettingsPalette.danger,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _SaveButton(
                saving: saving,
                onPressed: saving ? null : cubit.submit,
              ),
              const SizedBox(height: 10),
              _CancelButton(onPressed: saving ? null : _close),
            ],
          ),
        ),
      ],
    );
  }

  String? _fieldError(AddNetworkEditing s, NetworkField field) {
    final error = s.errors[field];
    if (error == null) return null;
    return switch (error) {
      NetworkFieldError.required => 'This field is required',
      NetworkFieldError.tooLong =>
        'Keep it under ${NetworkDraft.maxNameLength} characters',
      NetworkFieldError.invalidUrl =>
        'Enter a full URL, e.g. https://rpc.example.com',
      NetworkFieldError.insecureUrl =>
        'Use https:// — plain http can be tampered with in transit',
      NetworkFieldError.invalidChainId => 'Enter a positive whole number',
      NetworkFieldError.invalidSymbol => 'Use 2–6 letters or digits',
      NetworkFieldError.chainIdMismatch => _mismatchMessage(s),
    };
  }

  String _mismatchMessage(AddNetworkEditing s) {
    final rpc = s.rpc;
    return rpc is RpcReachable
        ? 'The RPC reports chain ID ${rpc.chainId}, not this one'
        : "Doesn't match the RPC";
  }

  /// Footer of the Chain ID card: verified, mismatched, or a reminder that
  /// the check happens on save.
  Widget? _chainIdNote(AddNetworkEditing s) {
    return switch (s.chainIdCheck) {
      ChainIdCheck.matches => const NetworkFieldNote(
          icon: Icons.verified_outlined,
          text: 'Matches RPC',
          color: SettingsPalette.accent,
        ),
      ChainIdCheck.mismatch => NetworkFieldNote(
          icon: Icons.error_outline_rounded,
          text: _mismatchMessage(s),
          color: SettingsPalette.danger,
        ),
      ChainIdCheck.unknown => const NetworkFieldNote(text: 'Verified on save'),
    };
  }

  String _saveFailureMessage(AppFailure failure) => switch (failure) {
        NetworkFailure() =>
          "Couldn't reach this RPC endpoint. Check the URL and your connection.",
        ChainErrorFailure() => "That endpoint didn't answer like an EVM node.",
        DuplicateNetworkFailure() =>
          'A network with this chain ID and RPC URL is already saved.',
        _ => 'Something went wrong. Please try again.',
      };
}

/// Two soft blobs behind the page: a faint lime one top-right and a grey
/// one mid-left. Static, so it is cached on its own layer.
class _NetworkAmbient extends StatelessWidget {
  const _NetworkAmbient();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned(
            right: -96,
            top: -96,
            child: _Blob(
              size: 320,
              sigma: 60,
              color: SettingsPalette.accent.withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            left: -128,
            top: 308,
            child: _Blob(
              size: 288,
              sigma: 50,
              color: SettingsPalette.chip.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.sigma, required this.color});

  final double size;
  final double sigma;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _IntroHeader extends StatelessWidget {
  const _IntroHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'CUSTOM RPC CONFIG',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SettingsPalette.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.55,
                ),
              ),
            ),
            SizedBox(width: 12),
            _KeysPill(),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Configure private high-throughput endpoints for bespoke MEV '
          'protection and low-latency routing.',
          style: TextStyle(
            color: SettingsPalette.textSecondary,
            fontSize: 12,
            height: 1.65,
            letterSpacing: 0.12,
          ),
        ),
      ],
    );
  }
}

/// Reassurance pill: adding a network only changes where the app reads
/// chain data from. Keys never leave the vault.
class _KeysPill extends StatelessWidget {
  const _KeysPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xCC2A292E),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SettingsPalette.accent,
              boxShadow: [
                BoxShadow(
                  color: SettingsPalette.accent.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.shield_outlined,
            size: 12,
            color: SettingsPalette.accent,
          ),
          const SizedBox(width: 6),
          const Text(
            'KEYS STAY ON DEVICE',
            style: TextStyle(
              color: SettingsPalette.accent,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.07,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetsLabel extends StatelessWidget {
  const _PresetsLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.bolt_rounded, size: 14, color: SettingsPalette.accent),
        SizedBox(width: 6),
        Text(
          'Select a popular network',
          style: TextStyle(
            color: SettingsPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.24,
          ),
        ),
      ],
    );
  }
}

class _NamePill extends StatelessWidget {
  const _NamePill({required this.isPreset});

  final bool isPreset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: SettingsPalette.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPreset ? Icons.verified_outlined : Icons.edit_outlined,
            size: 10,
            color: SettingsPalette.accent,
          ),
          const SizedBox(width: 4),
          Text(
            isPreset ? 'Preset' : 'Custom',
            style: const TextStyle(
              color: SettingsPalette.accent,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.07,
            ),
          ),
        ],
      ),
    );
  }
}

class _GasChip extends StatelessWidget {
  const _GasChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: SettingsPalette.chip,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'GAS',
        style: TextStyle(
          color: SettingsPalette.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.07,
        ),
      ),
    );
  }
}

class _InlineIconButton extends StatelessWidget {
  const _InlineIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
      color: color,
      disabledColor: color.withValues(alpha: 0.35),
      icon: Icon(icon),
    );
  }
}

class _SecurityWarning extends StatelessWidget {
  const _SecurityWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xE61B1B1F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SettingsPalette.dangerBadge.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.gpp_maybe_outlined,
              size: 18,
              color: SettingsPalette.danger,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MALICIOUS RPC RISK',
                  style: TextStyle(
                    color: SettingsPalette.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'An RPC provider can see your IP address and the addresses '
                  'you query, log your activity, and return false balances. '
                  'Only add endpoints you trust.',
                  style: TextStyle(
                    color: SettingsPalette.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                    letterSpacing: 0.12,
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

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saving, required this.onPressed});

  final bool saving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: SettingsPalette.accent.withValues(alpha: 0.3),
            blurRadius: 24,
          ),
        ],
      ),
      child: Material(
        color: SettingsPalette.accent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (saving)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: SettingsPalette.onAccent,
                    ),
                  )
                else
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: SettingsPalette.onAccent,
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    saving ? 'Verifying…' : 'Verify & Save Network',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SettingsPalette.onAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SettingsPalette.card.withValues(alpha: 0.6),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: const SizedBox(
          height: 46,
          child: Center(
            child: Text(
              'Cancel & Discard',
              style: TextStyle(
                color: SettingsPalette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
