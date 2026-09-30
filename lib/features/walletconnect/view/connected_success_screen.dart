import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design_system/dapp_icon.dart';
import '../../../core/design_system/lexor_card.dart';
import '../../../core/design_system/lexor_page_scaffold.dart';
import '../../../core/design_system/lexor_palette.dart';
import '../view_model/pairing_cubit.dart';
import '../view_model/pairing_state.dart';
import 'widgets/chain_badge.dart';
import 'widgets/verification_tag.dart';

/// "Connected" confirmation after a session is approved.
class ConnectedSuccessScreen extends StatelessWidget {
  const ConnectedSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PairingCubit>();
    return PopScope(
      // Whichever way the user leaves, the flow is over.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.reset();
      },
      child: BlocBuilder<PairingCubit, PairingState>(
        builder: (context, state) {
          final session = state is PairingConnected ? state.session : null;
          return LexorPageScaffold(
            title: 'Connected',
            child: session == null
                ? const Center(
                    child: Text(
                      'Nothing to show.',
                      style: TextStyle(color: LexorPalette.textSecondary),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const _CheckBadge(),
                                  const SizedBox(height: 28),
                                  Text(
                                    'Connected to ${session.dapp.name}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: LexorPalette.textPrimary,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'You can return to the app now. '
                                    'Every transaction and signature it '
                                    'requests will ask for your approval.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: LexorPalette.textSecondary,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  LexorCard(
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            DappIcon(
                                              name: session.dapp.name,
                                              brandColor:
                                                  session.dapp.brandColor,
                                              iconUrl: session.dapp.iconUrl,
                                              size: 44,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    session.dapp.name,
                                                    style: const TextStyle(
                                                      color: LexorPalette
                                                          .textPrimary,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    session.dapp.host,
                                                    style: const TextStyle(
                                                      color: LexorPalette
                                                          .textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            VerificationTag(
                                              session.dapp.verification,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            for (final chain in session.chains)
                                              _ChainChip(
                                                name: chain.name,
                                                badge:
                                                    ChainBadge(chain: chain, size: 20),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _Button(
                          label: 'Done',
                          primary: true,
                          onPressed: () {
                            if (context.canPop()) context.pop();
                          },
                        ),
                        const SizedBox(height: 12),
                        _Button(
                          label: 'View session',
                          primary: false,
                          onPressed: () => context.pushReplacement(
                            Routes.walletConnectSessionPath(session.topic),
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LexorPalette.accent.withValues(alpha: 0.14),
        boxShadow: [
          BoxShadow(
            color: LexorPalette.accent.withValues(alpha: 0.3),
            blurRadius: 40,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: LexorPalette.accent,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 36,
            color: LexorPalette.onAccentDark,
          ),
        ),
      ),
    );
  }
}

class _ChainChip extends StatelessWidget {
  const _ChainChip({required this.name, required this.badge});

  final String name;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
      decoration: BoxDecoration(
        color: LexorPalette.chipSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              color: LexorPalette.textPrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final bool primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: primary ? LexorPalette.accent : LexorPalette.chip,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: primary
                    ? LexorPalette.onAccent
                    : LexorPalette.textPrimary,
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
