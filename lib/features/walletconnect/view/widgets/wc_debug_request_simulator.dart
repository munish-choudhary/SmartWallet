import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/lexor_card.dart';
import '../../../../core/design_system/lexor_palette.dart';
import '../../data/wc_demo_data.dart';
import '../../view_model/wallet_connect_cubit.dart';

/// Debug-only: fabricates dApp requests so the review sheets can be
/// previewed. The hub only builds this under `kDebugMode`.
class WcDebugRequestSimulator extends StatelessWidget {
  const WcDebugRequestSimulator({super.key});

  static const _kinds = <(WcSimulatedRequestKind, String)>[
    (WcSimulatedRequestKind.message, 'Sign message'),
    (WcSimulatedRequestKind.typedData, 'Typed data'),
    (WcSimulatedRequestKind.swap, 'Swap tx'),
    (WcSimulatedRequestKind.unlimitedApproval, 'Unlimited approval'),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WalletConnectCubit>();
    return LexorCard(
      borderColor: LexorPalette.cautionBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LexorSectionLabel('Developer · simulate request'),
          const SizedBox(height: 4),
          const Text(
            'Debug builds only. Sends a fake request from the first '
            'connected app so you can preview each review sheet.',
            style: TextStyle(color: LexorPalette.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (kind, label) in _kinds)
                ActionChip(
                  label: Text(label),
                  labelStyle: const TextStyle(
                    color: LexorPalette.textPrimary,
                    fontSize: 12,
                  ),
                  backgroundColor: LexorPalette.chip,
                  side: BorderSide.none,
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final sent = await cubit.simulateRequest(kind);
                    if (!sent) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Connect an app first.'),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
