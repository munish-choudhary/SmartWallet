import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/dapp_icon.dart';
import '../../../../core/design_system/lexor_card.dart';
import '../../../../core/design_system/lexor_palette.dart';
import '../../data/models/wc_chain.dart';
import '../../data/models/wc_dapp.dart';
import '../../data/models/wc_session_proposal.dart';
import '../../view_model/pairing_cubit.dart';
import '../../view_model/pairing_state.dart';
import 'chain_badge.dart';
import 'verification_tag.dart';
import 'wc_permission_info.dart';

/// Shows the proposal sheet wired to [PairingCubit]. Dismissing the sheet
/// without choosing counts as a rejection.
Future<void> showSessionProposalSheet(
  BuildContext context, {
  required WcSessionProposal proposal,
}) async {
  final cubit = context.read<PairingCubit>();
  var decided = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => BlocProvider.value(
      value: cubit,
      child: BlocBuilder<PairingCubit, PairingState>(
        builder: (context, state) => SessionProposalSheet(
          proposal: proposal,
          busy: state is PairingApproving,
          onApprove: (chains) {
            decided = true;
            cubit.approve(chains);
          },
          onReject: () {
            decided = true;
            cubit.reject();
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
    ),
  );
  if (!decided) await cubit.reject();
}

class SessionProposalSheet extends StatefulWidget {
  const SessionProposalSheet({
    super.key,
    required this.proposal,
    required this.onApprove,
    required this.onReject,
    this.busy = false,
  });

  final WcSessionProposal proposal;
  final ValueChanged<List<WcChain>> onApprove;
  final VoidCallback onReject;
  final bool busy;

  @override
  State<SessionProposalSheet> createState() => _SessionProposalSheetState();
}

class _SessionProposalSheetState extends State<SessionProposalSheet> {
  late final Set<WcChain> _selected = {
    ...widget.proposal.requiredChains,
    ...widget.proposal.optionalChains,
  };

  @override
  Widget build(BuildContext context) {
    final proposal = widget.proposal;
    final dapp = proposal.dapp;
    final flagged = dapp.verification == WcVerification.flagged;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: LexorPalette.sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: LexorPalette.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Identity(dapp: dapp),
                      const SizedBox(height: 16),
                      ..._verificationNotice(dapp),
                      const LexorSectionLabel('This app wants to'),
                      const SizedBox(height: 8),
                      for (final permission in proposal.permissions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: LexorPalette.inset,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  permission.icon,
                                  size: 17,
                                  color: LexorPalette.accent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    permission.description,
                                    style: const TextStyle(
                                      color: LexorPalette.textPrimary,
                                      fontSize: 12,
                                      height: 16 / 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      const LexorSectionLabel('Networks'),
                      const SizedBox(height: 8),
                      for (final chain in proposal.allChains)
                        _ChainToggle(
                          chain: chain,
                          required: proposal.requiredChains.contains(chain),
                          selected: _selected.contains(chain),
                          onChanged: (on) => setState(() {
                            on ? _selected.add(chain) : _selected.remove(chain);
                          }),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Reject',
                        background:
                            flagged ? LexorPalette.accent : LexorPalette.chip,
                        foreground: flagged
                            ? LexorPalette.onAccent
                            : LexorPalette.textPrimary,
                        onPressed: widget.busy ? null : widget.onReject,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _ActionButton(
                        label: flagged ? 'Connect anyway' : 'Connect',
                        background: flagged
                            ? LexorPalette.dangerFill
                            : LexorPalette.accent,
                        foreground: flagged
                            ? LexorPalette.danger
                            : LexorPalette.onAccent,
                        loading: widget.busy,
                        onPressed: widget.busy
                            ? null
                            : () => widget.onApprove(
                                  proposal.allChains
                                      .where(_selected.contains)
                                      .toList(),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _verificationNotice(WcDapp dapp) {
    switch (dapp.verification) {
      case WcVerification.verified:
        return const [];
      case WcVerification.unverified:
        return const [
          LexorNotice(
            title: "We couldn't verify this app",
            body: 'Check that the address above is exactly the site you '
                'meant to connect to.',
          ),
          SizedBox(height: 16),
        ];
      case WcVerification.flagged:
        return const [
          LexorNotice(
            title: 'Flagged as malicious',
            body: 'This app was reported as a scam or is impersonating '
                'another site. We strongly recommend rejecting.',
            severity: LexorNoticeSeverity.danger,
          ),
          SizedBox(height: 16),
        ];
    }
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.dapp});

  final WcDapp dapp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DappIcon(
          name: dapp.name,
          brandColor: dapp.brandColor,
          iconUrl: dapp.iconUrl,
          size: 64,
          glow: true,
        ),
        const SizedBox(height: 12),
        Text(
          '${dapp.name} wants to connect',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: LexorPalette.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dapp.host,
          style: const TextStyle(
            color: LexorPalette.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        VerificationTag(dapp.verification),
      ],
    );
  }
}

class _ChainToggle extends StatelessWidget {
  const _ChainToggle({
    required this.chain,
    required this.required,
    required this.selected,
    required this.onChanged,
  });

  final WcChain chain;
  final bool required;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LexorPalette.chipSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ChainBadge(chain: chain),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              chain.name,
              style: const TextStyle(
                color: LexorPalette.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          if (required)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text(
                'REQUIRED',
                style: TextStyle(
                  color: LexorPalette.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          Switch(
            value: selected,
            onChanged: required ? null : onChanged,
            activeThumbColor: LexorPalette.onAccent,
            activeTrackColor: LexorPalette.accent,
            inactiveThumbColor: LexorPalette.textSecondary,
            inactiveTrackColor: LexorPalette.chip,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Material(
        color: background,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: foreground,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
