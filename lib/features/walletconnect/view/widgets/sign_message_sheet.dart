import 'package:flutter/material.dart';

import '../../../../core/design_system/lexor_card.dart';
import '../../../../core/design_system/lexor_palette.dart';
import '../../data/models/wc_request.dart';
import '../../data/models/wc_session.dart';
import 'request_sheet_frame.dart';

/// `personal_sign` review. Shows the exact text being signed — the user
/// must be able to read what they are putting their name to.
class SignMessageSheet extends StatelessWidget {
  const SignMessageSheet({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
    this.busy = false,
    this.queued = 0,
  });

  final WcPersonalSignRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool busy;
  final int queued;

  @override
  Widget build(BuildContext context) {
    return RequestSheetFrame(
      request: request,
      title: 'Signature request',
      busy: busy,
      queued: queued,
      onReject: onReject,
      onApprove: onApprove,
      approveLabel: 'Sign',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!request.messageIsReadable) ...[
            const LexorNotice(
              title: 'Unreadable message',
              body: 'This is raw data, not text. Only sign it if you '
                  'understand exactly what it does.',
            ),
            const SizedBox(height: 12),
          ],
          const LexorSectionLabel('Message'),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Scrollbar(
              child: SingleChildScrollView(
                child: SelectableText(
                  request.message,
                  style: TextStyle(
                    color: LexorPalette.textPrimary,
                    fontSize: 13,
                    height: 1.45,
                    fontFamily: request.messageIsReadable ? null : 'monospace',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SheetCard(
            child: Column(
              children: [
                SheetRow(label: 'Account', value: shortenAddress(request.signer)),
                SheetRow(label: 'Network', value: request.chain.name),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const LexorNotice(
            title: 'No gas fee',
            body: 'Signing a message does not send a transaction, but '
                'apps can use signatures to log you in or authorize actions.',
            severity: LexorNoticeSeverity.info,
          ),
        ],
      ),
    );
  }
}
