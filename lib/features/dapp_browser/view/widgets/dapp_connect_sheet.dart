import 'package:flutter/material.dart';

import '../../../../core/design_system/dapp_icon.dart';
import '../../../../core/design_system/lexor_card.dart';
import '../../../../core/design_system/lexor_palette.dart';
import '../../../walletconnect/data/models/wc_dapp.dart';
import '../../../walletconnect/data/models/wc_session.dart';
import '../../../walletconnect/data/wallet_account_source.dart';
import '../../../walletconnect/view/widgets/request_sheet_frame.dart';
import '../../../walletconnect/view/widgets/verification_tag.dart';
import '../../../walletconnect/view/widgets/wc_permission_info.dart';

/// "Connect wallet" confirmation for a page calling `eth_requestAccounts`.
/// Resolves true only on an explicit Connect tap; dismissing rejects.
Future<bool> showDappConnectSheet(
  BuildContext context, {
  required WcDapp dapp,
  required WalletAccount account,
}) async {
  final approved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DappConnectSheet(
      dapp: dapp,
      account: account,
      onConnect: () => Navigator.of(sheetContext).pop(true),
      onReject: () => Navigator.of(sheetContext).pop(false),
    ),
  );
  return approved ?? false;
}

class DappConnectSheet extends StatelessWidget {
  const DappConnectSheet({
    super.key,
    required this.dapp,
    required this.account,
    required this.onConnect,
    required this.onReject,
  });

  final WcDapp dapp;
  final WalletAccount account;
  final VoidCallback onConnect;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
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
                      Center(
                        child: DappIcon(
                          name: dapp.name,
                          brandColor: dapp.brandColor,
                          size: 64,
                          glow: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Connect to ${dapp.name}?',
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
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: LexorPalette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(child: VerificationTag(dapp.verification)),
                      const SizedBox(height: 16),
                      if (dapp.verification != WcVerification.verified) ...[
                        const LexorNotice(
                          title: "We couldn't verify this site",
                          body: 'Check the address above is exactly the site '
                              'you meant to use before connecting.',
                        ),
                        const SizedBox(height: 16),
                      ],
                      SheetCard(
                        label: 'Account',
                        child: Column(
                          children: [
                            SheetRow(label: 'Name', value: account.label),
                            SheetRow(
                              label: 'Address',
                              value: shortenAddress(account.address),
                              mono: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const LexorSectionLabel('This site will be able to'),
                      const SizedBox(height: 8),
                      for (final permission in const [
                        WcPermission.viewAccount,
                        WcPermission.sendTransactions,
                      ])
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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _Button(
                        label: 'Reject',
                        background: LexorPalette.chip,
                        foreground: LexorPalette.textPrimary,
                        onPressed: onReject,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _Button(
                        label: 'Connect',
                        background: LexorPalette.accent,
                        foreground: LexorPalette.onAccent,
                        onPressed: onConnect,
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
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

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
            child: Text(
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
