import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/dapp_icon.dart';
import '../../../../core/design_system/lexor_card.dart';
import '../../../../core/design_system/lexor_palette.dart';
import '../../../walletconnect/data/models/wc_chain.dart';
import '../../../walletconnect/data/models/wc_session.dart';
import '../../../walletconnect/view/widgets/chain_badge.dart';
import '../../../walletconnect/view/widgets/verification_tag.dart';
import '../../data/eip1193/dapp_identity.dart';
import '../../data/models/dapp_connection.dart';

/// What the current site can see, which network it is on, and a
/// Disconnect button. Opened from the browser's bottom bar.
class BrowserConnectionSheet extends StatelessWidget {
  const BrowserConnectionSheet({
    super.key,
    required this.origin,
    required this.connection,
    required this.chain,
    required this.onSwitchChain,
    required this.onDisconnect,
  });

  /// `https://app.uniswap.org`
  final String origin;

  /// Null when the site isn't connected.
  final DappConnection? connection;
  final WcChain chain;
  final ValueChanged<WcChain> onSwitchChain;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final dapp = DappIdentity.forOrigin(origin);
    final connection = this.connection;
    return Container(
      decoration: const BoxDecoration(
        color: LexorPalette.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 16),
              Row(
                children: [
                  DappIcon(
                    name: dapp.name,
                    brandColor: dapp.brandColor,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dapp.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: LexorPalette.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          dapp.host,
                          style: const TextStyle(
                            color: LexorPalette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  VerificationTag(dapp.verification),
                ],
              ),
              const SizedBox(height: 20),
              if (connection == null)
                const LexorNotice(
                  title: 'Not connected',
                  body: "This site can't see your account. Use the site's "
                      '"Connect Wallet" button to connect, and you will be '
                      'asked to approve first.',
                  severity: LexorNoticeSeverity.info,
                )
              else ...[
                _AccountRow(address: connection.address),
                const SizedBox(height: 16),
                const LexorSectionLabel('Network'),
                const SizedBox(height: 8),
                for (final option in WcChains.all)
                  _ChainOption(
                    chain: option,
                    selected: option == chain,
                    onTap: () {
                      onSwitchChain(option);
                      Navigator.of(context).pop();
                    },
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: Material(
                    color: LexorPalette.dangerFill,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () {
                        onDisconnect();
                        Navigator.of(context).pop();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.link_off_rounded,
                            size: 17,
                            color: LexorPalette.danger,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Disconnect',
                            style: TextStyle(
                              color: LexorPalette.danger,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return LexorCard(
      color: LexorPalette.cardSolid,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: LexorPalette.chip,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 16,
              color: LexorPalette.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connected account',
                  style: TextStyle(
                    color: LexorPalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  shortenAddress(address),
                  style: const TextStyle(
                    color: LexorPalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: address));
              messenger.showSnackBar(
                const SnackBar(content: Text('Address copied')),
              );
            },
            tooltip: 'Copy address',
            icon: const Icon(
              Icons.copy_rounded,
              size: 18,
              color: LexorPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChainOption extends StatelessWidget {
  const _ChainOption({
    required this.chain,
    required this.selected,
    required this.onTap,
  });

  final WcChain chain;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? const Color.fromRGBO(212, 238, 107, 0.12)
            : LexorPalette.chipSoft,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: LexorPalette.accent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
