import 'package:flutter/material.dart';

import '../../../../core/design_system/dapp_icon.dart';
import '../../../../core/design_system/lexor_card.dart';
import '../../../../core/design_system/lexor_palette.dart';
import '../../data/models/wc_dapp.dart';
import '../../data/models/wc_session.dart';
import '../wc_formatters.dart';
import 'chain_badge.dart';

/// One connected dApp in the hub's list. Static glass (no live blur) so
/// it's cheap inside a list.
class WcActiveSessionCard extends StatelessWidget {
  const WcActiveSessionCard({
    super.key,
    required this.session,
    required this.onTap,
    this.now,
  });

  final WcSession session;
  final VoidCallback onTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final dapp = session.dapp;
    return LexorCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          DappIcon(
            name: dapp.name,
            brandColor: dapp.brandColor,
            iconUrl: dapp.iconUrl,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        dapp.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LexorPalette.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (dapp.verification == WcVerification.verified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: LexorPalette.accent,
                        semanticLabel: 'Verified',
                      ),
                    ],
                  ],
                ),
                Text(
                  dapp.host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LexorPalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final chain in session.chains.take(4)) ...[
                      ChainBadge(chain: chain, size: 20),
                      const SizedBox(width: 4),
                    ],
                    if (session.chains.length > 4)
                      Text(
                        '+${session.chains.length - 4}',
                        style: const TextStyle(
                          color: LexorPalette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        formatRelative(session.lastActivityAt, now: now),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LexorPalette.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: LexorPalette.textSecondary,
          ),
        ],
      ),
    );
  }
}
