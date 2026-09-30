import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/design_system/dapp_icon.dart';
import '../../../core/design_system/lexor_card.dart';
import '../../../core/design_system/lexor_page_scaffold.dart';
import '../../../core/design_system/lexor_palette.dart';
import '../data/models/wc_chain.dart';
import '../data/models/wc_session.dart';
import '../view_model/session_detail_cubit.dart';
import '../view_model/session_detail_state.dart';
import 'widgets/chain_badge.dart';
import 'widgets/verification_tag.dart';
import 'widgets/wc_permission_info.dart';
import 'wc_formatters.dart';

/// "Connected App Detail" frame: everything a connected dApp can do and
/// when the session ends, with a one-tap disconnect.
class ConnectedAppDetailScreen extends StatelessWidget {
  const ConnectedAppDetailScreen({super.key, this.now});

  /// Clock override for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionDetailCubit, SessionDetailState>(
      listener: (context, state) {
        if (state is SessionDetailDisconnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Disconnected from ${state.session.dapp.name}')),
          );
          if (context.canPop()) context.pop();
        } else if (state is SessionDetailDisconnectFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not disconnect. Try again.')),
          );
        }
      },
      builder: (context, state) {
        final session = switch (state) {
          SessionDetailReady(:final session) => session,
          SessionDetailDisconnecting(:final session) => session,
          SessionDetailDisconnectFailed(:final session) => session,
          SessionDetailDisconnected(:final session) => session,
          _ => null,
        };
        return LexorPageScaffold(
          title: 'Connected App',
          trailing: session == null
              ? null
              : LexorHeaderAction(
                  icon: Icons.open_in_new_rounded,
                  semanticLabel: 'Open ${session.dapp.name} in browser',
                  onPressed: () =>
                      context.push(Routes.dappBrowsePath(session.dapp.url)),
                ),
          scrollable: session != null,
          child: session != null
              ? _Content(
                  session: session,
                  busy: state is SessionDetailDisconnecting,
                  now: now,
                )
              : switch (state) {
                  SessionDetailNotFound() => const _Message(
                      icon: Icons.link_off_rounded,
                      title: 'Session not found',
                      body: 'This app is no longer connected.',
                    ),
                  _ => const Center(
                      child: CircularProgressIndicator(
                        color: LexorPalette.accent,
                      ),
                    ),
                },
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.session, required this.busy, this.now});

  final WcSession session;
  final bool busy;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final clock = now ?? DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.center,
          child: _TelemetryPill(label: 'Encrypted session active'),
        ),
        const SizedBox(height: 16),
        _HeroCard(session: session),
        const SizedBox(height: 16),
        _AccountCard(session: session),
        const SizedBox(height: 16),
        _NetworksCard(chains: session.chains),
        const SizedBox(height: 16),
        _PermissionsCard(permissions: session.permissions),
        const SizedBox(height: 16),
        _TimelineCard(session: session, now: clock),
        const SizedBox(height: 16),
        const _SecurityNote(),
        const SizedBox(height: 24),
        _DisconnectButton(
          busy: busy,
          onPressed: () => _confirmDisconnect(context),
        ),
      ],
    );
  }

  Future<void> _confirmDisconnect(BuildContext context) async {
    final cubit = context.read<SessionDetailCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LexorPalette.cardSolid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Disconnect ${session.dapp.name}?',
          style: const TextStyle(
            color: LexorPalette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'It will lose access to your account immediately and can no '
          'longer request signatures. You can reconnect at any time.',
          style: TextStyle(color: LexorPalette.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: LexorPalette.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Disconnect',
              style: TextStyle(
                color: LexorPalette.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.disconnect();
  }
}

/// Top pill with a pulsing dot.
class _TelemetryPill extends StatelessWidget {
  const _TelemetryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(42, 41, 46, 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulseDot(),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: LexorPalette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.55,
              height: 14 / 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      height: 8,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Opacity(
                opacity: (1 - t) * 0.75,
                child: Transform.scale(
                  scale: 1 + t * 1.8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: LexorPalette.accent,
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: LexorPalette.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.session});

  final WcSession session;

  @override
  Widget build(BuildContext context) {
    final dapp = session.dapp;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: LexorPalette.card,
              child: const _HeroGlows(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: LexorPalette.chipMuted,
                        ),
                        child: DappIcon(
                          name: dapp.name,
                          brandColor: dapp.brandColor,
                          iconUrl: dapp.iconUrl,
                          size: 56,
                          glow: true,
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: LexorPalette.accent,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: LexorPalette.onAccentDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  dapp.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LexorPalette.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.36,
                    height: 32 / 24,
                  ),
                ),
                const SizedBox(height: 4),
                _LinkPill(host: dapp.host),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in dapp.tags) LexorTag(tag),
                    VerificationTag(dapp.verification),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroGlows extends StatelessWidget {
  const _HeroGlows();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          right: -48,
          top: -48,
          child: _blob(144, const Color.fromRGBO(212, 238, 107, 0.1), 32),
        ),
        Positioned(
          left: -40,
          bottom: -40,
          child: _blob(128, const Color.fromRGBO(236, 220, 255, 0.1), 20),
        ),
      ],
    );
  }

  static Widget _blob(double size, Color color, double sigma) {
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

class _LinkPill extends StatelessWidget {
  const _LinkPill({required this.host});

  final String host;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: LexorPalette.chipSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              host,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LexorPalette.textSecondary,
                fontSize: 12,
                letterSpacing: 0.12,
                height: 16 / 12,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.open_in_new_rounded,
            size: 11,
            color: LexorPalette.accent,
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.session});

  final WcSession session;

  @override
  Widget build(BuildContext context) {
    return LexorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LexorSectionLabel(
            'Connected account',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: LexorPalette.badge,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'EVM WALLET',
                style: TextStyle(
                  color: LexorPalette.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.44,
                  height: 14 / 11,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: LexorPalette.chip,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 17,
                  color: LexorPalette.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.accountLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LexorPalette.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        height: 28 / 20,
                      ),
                    ),
                    Text(
                      session.shortAddress,
                      style: const TextStyle(
                        color: LexorPalette.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.65,
                        height: 18 / 13,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: const Color.fromRGBO(42, 41, 46, 0.8),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(
                      ClipboardData(text: session.accountAddress),
                    );
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Address copied')),
                    );
                  },
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.copy_rounded,
                      size: 15,
                      color: LexorPalette.textPrimary,
                      semanticLabel: 'Copy address',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetworksCard extends StatelessWidget {
  const _NetworksCard({required this.chains});

  final List<WcChain> chains;

  @override
  Widget build(BuildContext context) {
    return LexorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LexorSectionLabel('Authorized networks'),
          const SizedBox(height: 10),
          for (var i = 0; i < chains.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _NetworkRow(chain: chains[i]),
          ],
        ],
      ),
    );
  }
}

class _NetworkRow extends StatelessWidget {
  const _NetworkRow({required this.chain});

  final WcChain chain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: LexorPalette.chipSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ChainBadge(chain: chain),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chain.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LexorPalette.textPrimary,
                    fontSize: 14,
                    letterSpacing: 0.07,
                    height: 20 / 14,
                  ),
                ),
                Text(
                  'CHAIN ID: ${chain.chainId}',
                  style: const TextStyle(
                    color: LexorPalette.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.44,
                    height: 14 / 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: LexorPalette.accent,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Active',
                style: TextStyle(
                  color: LexorPalette.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.44,
                  height: 14 / 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard({required this.permissions});

  final List<WcPermission> permissions;

  @override
  Widget build(BuildContext context) {
    return LexorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LexorSectionLabel(
            'Granted access',
            trailing: Text(
              '${permissions.length} ACTIVE',
              style: const TextStyle(
                color: LexorPalette.accentMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.44,
                height: 14 / 11,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < permissions.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LexorPalette.inset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      permissions[i].icon,
                      size: 16.67,
                      color: LexorPalette.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      permissions[i].description,
                      style: const TextStyle(
                        color: LexorPalette.textPrimary,
                        fontSize: 12,
                        letterSpacing: 0.12,
                        height: 16 / 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.session, required this.now});

  final WcSession session;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Connected', formatDateTime(session.connectedAt)),
      ('Expires in', formatRemaining(session.expiresAt, now: now)),
      (
        'Last activity',
        '${formatRelative(session.lastActivityAt, now: now)} · '
            '${session.lastActivityLabel}',
      ),
    ];
    return LexorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LexorSectionLabel('Session timeline'),
          const SizedBox(height: 10),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 10),
              const Divider(
                height: 1,
                thickness: 1,
                color: LexorPalette.divider,
              ),
              const SizedBox(height: 10),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rows[i].$1,
                  style: const TextStyle(
                    color: LexorPalette.textSecondary,
                    fontSize: 12,
                    letterSpacing: 0.12,
                    height: 16 / 12,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    rows[i].$2,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: LexorPalette.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.44,
                      height: 14 / 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(42, 41, 46, 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.gpp_maybe_outlined,
              size: 17.5,
              color: Color(0xFF8E9079),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Lexor Pocket never shares your private keys or recovery phrase '
              'with connected apps. Disconnecting immediately revokes every '
              'permission granted to this session.',
              style: TextStyle(
                color: LexorPalette.textSecondary,
                fontSize: 12,
                letterSpacing: 0.12,
                height: 16 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisconnectButton extends StatelessWidget {
  const _DisconnectButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Material(
        color: LexorPalette.dangerFill,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: busy ? null : onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: LexorPalette.danger,
                  ),
                )
              else ...[
                const Icon(
                  Icons.link_off_rounded,
                  size: 17,
                  color: LexorPalette.danger,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Disconnect Session',
                  style: TextStyle(
                    color: LexorPalette.danger,
                    fontSize: 16,
                    height: 24 / 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: LexorPalette.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: LexorPalette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: LexorPalette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
