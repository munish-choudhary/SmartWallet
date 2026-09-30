import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design_system/dapp_icon.dart';
import '../../../core/design_system/lexor_page_scaffold.dart';
import '../../../core/design_system/lexor_palette.dart';
import '../../../core/result/result.dart';
import '../view_model/pairing_cubit.dart';
import '../view_model/pairing_state.dart';
import 'widgets/session_proposal_sheet.dart';

/// Shown while pairing: waiting for the app's connection request, then
/// hosting the proposal sheet, then handing off to the success screen.
class ConnectingPairingScreen extends StatefulWidget {
  const ConnectingPairingScreen({super.key});

  @override
  State<ConnectingPairingScreen> createState() =>
      _ConnectingPairingScreenState();
}

class _ConnectingPairingScreenState extends State<ConnectingPairingScreen> {
  /// The proposal the sheet was last opened for, so a state that is seen
  /// both at mount and through the listener opens one sheet, not two.
  String? _sheetProposalId;

  @override
  void initState() {
    super.initState();
    // A `BlocListener` only hears *changes*. The relay can answer before
    // this route has finished mounting (it is pushed on `connecting`), so
    // whatever state we were born into has to be handled explicitly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handle(context.read<PairingCubit>().state);
    });
  }

  void _handle(PairingState state) {
    switch (state) {
      case PairingProposal(:final proposal):
        if (_sheetProposalId == proposal.id) return;
        _sheetProposalId = proposal.id;
        unawaited(showSessionProposalSheet(context, proposal: proposal));
      case PairingConnected():
        context.pushReplacement(Routes.walletConnectConnected);
      case PairingIdle():
        if (context.canPop()) context.pop();
      case PairingConnecting() || PairingApproving() || PairingFailure():
        break;
    }
  }

  void _leave(BuildContext context) {
    context.read<PairingCubit>().reset();
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        // System back / swipe. Never reset a finished flow: the success
        // screen still needs the connected session.
        final cubit = context.read<PairingCubit>();
        if (didPop && cubit.state is! PairingConnected) cubit.reset();
      },
      child: BlocConsumer<PairingCubit, PairingState>(
        listener: (context, state) => _handle(state),
        builder: (context, state) {
          return LexorPageScaffold(
            title: 'Connecting',
            onBack: () => _leave(context),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: switch (state) {
                  PairingFailure(:final failure) => _Failed(
                      message: _messageFor(failure),
                      onBack: () => _leave(context),
                    ),
                  PairingProposal(:final proposal) ||
                  PairingApproving(:final proposal) =>
                    _Waiting(
                      title: 'Review the request',
                      body: '${proposal.dapp.name} is waiting for your '
                          'decision.',
                      dappName: proposal.dapp.name,
                      dappColor: proposal.dapp.brandColor,
                      onCancel: null,
                    ),
                  _ => _Waiting(
                      title: 'Connecting…',
                      body: 'Waiting for the app to send its connection '
                          'request. This usually takes a few seconds.',
                      onCancel: () => _leave(context),
                    ),
                },
              ),
            ),
          );
        },
      ),
    );
  }

  static String _messageFor(AppFailure failure) => switch (failure) {
        UnknownFailure(:final message) => message,
        NetworkFailure() =>
          'We could not reach the WalletConnect relay. Check your '
              'connection and try again.',
        _ => 'Something went wrong while connecting. Please try again.',
      };
}

class _Waiting extends StatelessWidget {
  const _Waiting({
    required this.title,
    required this.body,
    required this.onCancel,
    this.dappName,
    this.dappColor,
  });

  final String title;
  final String body;
  final VoidCallback? onCancel;
  final String? dappName;
  final int? dappColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Orb(dappName: dappName, dappColor: dappColor),
        const SizedBox(height: 32),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: LexorPalette.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.36,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: LexorPalette.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        if (onCancel != null) ...[
          const SizedBox(height: 32),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(color: LexorPalette.textSecondary),
            ),
          ),
        ],
      ],
    );
  }
}

/// Wallet ↔ app link animation: two nodes with a pulsing ring.
class _Orb extends StatefulWidget {
  const _Orb({this.dappName, this.dappColor});

  final String? dappName;
  final int? dappColor;

  @override
  State<_Orb> createState() => _OrbState();
}

class _OrbState extends State<_Orb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: 240,
        height: 120,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                // travelling dots between the two nodes
                for (var i = 0; i < 3; i++)
                  Positioned(
                    left: 60 + 120 * ((t + i / 3) % 1),
                    child: Opacity(
                      opacity: 0.25 + 0.75 * (1 - ((t + i / 3) % 1 - 0.5).abs() * 2),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: LexorPalette.accent,
                        ),
                      ),
                    ),
                  ),
                Positioned(left: 0, child: _node(const _WalletNode())),
                Positioned(
                  right: 0,
                  child: _node(
                    widget.dappName == null
                        ? const _UnknownNode()
                        : DappIcon(
                            name: widget.dappName!,
                            brandColor: widget.dappColor ?? 0xFF7255A5,
                            size: 56,
                            glow: true,
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _node(Widget child) => Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: LexorPalette.chipMuted,
        ),
        child: child,
      );
}

class _WalletNode extends StatelessWidget {
  const _WalletNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF7255A5), LexorPalette.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.account_balance_wallet_rounded,
        color: LexorPalette.background,
      ),
    );
  }
}

class _UnknownNode extends StatelessWidget {
  const _UnknownNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: LexorPalette.chip,
      ),
      child: const Icon(Icons.public_rounded, color: LexorPalette.textSecondary),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: LexorPalette.dangerFill,
          ),
          child: const Icon(
            Icons.link_off_rounded,
            size: 32,
            color: LexorPalette.danger,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Couldn't connect",
          style: TextStyle(
            color: LexorPalette.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.36,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: LexorPalette.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: Material(
            color: LexorPalette.accent,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    'Back',
                    style: TextStyle(
                      color: LexorPalette.onAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
