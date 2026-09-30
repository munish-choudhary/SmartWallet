import 'package:flutter/material.dart';

import '../../../../core/design_system/lexor_card.dart';
import '../../../../core/design_system/lexor_palette.dart';
import '../../data/models/wc_request.dart';
import '../../data/models/wc_session.dart';
import 'request_sheet_frame.dart';

/// `eth_signTypedData_v4` review: domain plus the structured message.
class SignTypedDataSheet extends StatelessWidget {
  const SignTypedDataSheet({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
    this.busy = false,
    this.queued = 0,
  });

  final WcTypedDataRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool busy;
  final int queued;

  @override
  Widget build(BuildContext context) {
    return RequestSheetFrame(
      request: request,
      title: 'Sign typed data',
      busy: busy,
      queued: queued,
      onReject: onReject,
      onApprove: onApprove,
      approveLabel: request.authorizesTransfers ? 'Sign anyway' : 'Sign',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (request.authorizesTransfers) ...[
            const LexorNotice(
              title: 'This can authorize token transfers',
              body: 'Permit-style signatures let the spender move your '
                  'tokens without another transaction. Only sign if you '
                  'trust this app.',
              severity: LexorNoticeSeverity.danger,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              const Text(
                'Type',
                style: TextStyle(color: LexorPalette.textSecondary),
              ),
              const SizedBox(width: 8),
              LexorTag(request.primaryType),
            ],
          ),
          const SizedBox(height: 12),
          if (request.domain.isNotEmpty) ...[
            SheetCard(
              label: 'Domain',
              child: Column(
                children: [
                  for (final field in request.domain)
                    SheetRow(
                      label: field.label,
                      value: _short(field.value),
                      mono: field.value.startsWith('0x'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SheetCard(
            label: 'Message',
            child: Column(
              children: [
                for (final field in request.fields)
                  Padding(
                    padding: EdgeInsets.only(left: field.depth * 14.0),
                    child: field.value.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                field.label,
                                style: const TextStyle(
                                  color: LexorPalette.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        : SheetRow(
                            label: field.label,
                            value: _short(field.value),
                            mono: field.value.startsWith('0x'),
                          ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SheetCard(
            child: Column(
              children: [
                SheetRow(label: 'Account', value: shortenAddress(request.signer)),
                SheetRow(label: 'Network', value: request.chain.name),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _short(String value) =>
      value.startsWith('0x') && value.length > 20 ? shortenAddress(value) : value;
}
