import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/lexor_card.dart';
import '../../../../core/design_system/lexor_palette.dart';
import '../../data/models/wc_request.dart';
import '../../data/models/wc_session.dart';
import 'request_sheet_frame.dart';

/// `eth_sendTransaction` review: simulated balance changes, destination,
/// fee and risk flags. Unlimited token approvals get a warning and a
/// spending-cap field the user must fill in (or explicitly keep unlimited).
class TransactionRequestSheet extends StatefulWidget {
  const TransactionRequestSheet({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
    this.busy = false,
    this.queued = 0,
  });

  final WcTransactionRequest request;

  /// Receives the spending cap the user typed, or null when no cap applies
  /// (not an approval, or the user chose to keep it unlimited).
  final ValueChanged<String?> onApprove;
  final VoidCallback onReject;
  final bool busy;
  final int queued;

  @override
  State<TransactionRequestSheet> createState() =>
      _TransactionRequestSheetState();
}

class _TransactionRequestSheetState extends State<TransactionRequestSheet> {
  final _cap = TextEditingController();
  bool _keepUnlimited = false;

  WcTransactionRequest get _tx => widget.request;
  bool get _unlimited => _tx.approval?.isUnlimited ?? false;

  @override
  void dispose() {
    _cap.dispose();
    super.dispose();
  }

  bool get _capValid {
    final value = double.tryParse(_cap.text.trim());
    return value != null && value > 0;
  }

  bool get _canApprove => !_unlimited || _keepUnlimited || _capValid;

  @override
  Widget build(BuildContext context) {
    final hasDanger = _tx.risks.any((r) => r.severity == WcRiskSeverity.danger);
    return RequestSheetFrame(
      request: _tx,
      title: _tx.approval != null ? 'Approve spending' : 'Confirm transaction',
      busy: widget.busy,
      queued: widget.queued,
      onReject: widget.onReject,
      approveLabel: hasDanger && _keepUnlimited ? 'Approve anyway' : 'Approve',
      onApprove: _canApprove
          ? () => widget.onApprove(
                _unlimited && !_keepUnlimited ? _cap.text.trim() : null,
              )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final risk in _tx.risks) ...[
            LexorNotice(
              title: risk.title,
              body: risk.detail,
              severity: risk.severity == WcRiskSeverity.danger
                  ? LexorNoticeSeverity.danger
                  : LexorNoticeSeverity.caution,
            ),
            const SizedBox(height: 12),
          ],
          if (_tx.approval != null) ...[
            _approvalCard(_tx.approval!),
            const SizedBox(height: 12),
          ] else ...[
            _balanceChanges(),
            const SizedBox(height: 12),
          ],
          SheetCard(
            label: 'Details',
            child: Column(
              children: [
                SheetRow(
                  label: _tx.isContractCall ? 'Contract' : 'To',
                  value: shortenAddress(_tx.to),
                  mono: true,
                ),
                SheetRow(label: 'Network', value: _tx.chain.name),
                SheetRow(
                  label: 'Action',
                  value: _tx.methodName ??
                      (_tx.isContractCall ? 'Contract interaction' : 'Transfer'),
                ),
                if (_tx.approval == null)
                  SheetRow(
                    label: 'Value',
                    value: _withUsd(_tx.valueDisplay, _tx.valueUsd),
                  ),
                SheetRow(
                  label: 'Network fee',
                  value: _withUsd(_tx.networkFeeDisplay, _tx.networkFeeUsd),
                ),
                SheetRow(
                  label: 'Account',
                  value: shortenAddress(_tx.signer),
                  mono: true,
                ),
              ],
            ),
          ),
          if (_tx.dataHex != null && _tx.dataHex != '0x') ...[
            const SizedBox(height: 12),
            _RawData(hex: _tx.dataHex!),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _balanceChanges() {
    if (_tx.balanceChanges.isEmpty) {
      return const LexorNotice(
        title: 'No simulation available',
        body: 'We could not preview the result of this transaction. '
            'Review the details below carefully.',
      );
    }
    return SheetCard(
      label: 'Estimated balance changes',
      child: Column(
        children: [
          for (final change in _tx.balanceChanges)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    change.isOutgoing
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 18,
                    color: change.isOutgoing
                        ? LexorPalette.danger
                        : LexorPalette.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      change.isOutgoing ? 'You send' : 'You receive',
                      style: const TextStyle(
                        color: LexorPalette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${change.isOutgoing ? '-' : '+'}${change.amountDisplay} '
                    '${change.symbol}',
                    style: TextStyle(
                      color: change.isOutgoing
                          ? LexorPalette.danger
                          : LexorPalette.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _approvalCard(WcTokenApproval approval) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetCard(
          label: 'Token approval',
          child: Column(
            children: [
              SheetRow(label: 'Token', value: approval.tokenSymbol),
              SheetRow(
                label: 'Spender',
                value: shortenAddress(approval.spender),
                mono: true,
              ),
              SheetRow(
                label: 'Requested',
                value: approval.requestedAmountDisplay,
                valueColor: approval.isUnlimited
                    ? LexorPalette.danger
                    : LexorPalette.textPrimary,
              ),
            ],
          ),
        ),
        if (approval.isUnlimited) ...[
          const SizedBox(height: 12),
          const LexorSectionLabel('Spending cap'),
          const SizedBox(height: 8),
          TextField(
            controller: _cap,
            enabled: !_keepUnlimited,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: const TextStyle(color: LexorPalette.textPrimary),
            decoration: InputDecoration(
              hintText: 'Max ${approval.tokenSymbol} the spender can use',
              hintStyle: const TextStyle(color: LexorPalette.textDisabled),
              suffixText: approval.tokenSymbol,
              suffixStyle: const TextStyle(color: LexorPalette.textSecondary),
              filled: true,
              fillColor: LexorPalette.cardSolid,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _keepUnlimited = !_keepUnlimited),
              child: Text(
                _keepUnlimited
                    ? 'Set a spending cap instead'
                    : 'Keep unlimited (not recommended)',
                style: TextStyle(
                  color: _keepUnlimited
                      ? LexorPalette.accent
                      : LexorPalette.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _withUsd(String display, double? usd) =>
      usd == null ? display : '$display  (\$${usd.toStringAsFixed(2)})';
}

class _RawData extends StatelessWidget {
  const _RawData({required this.hex});

  final String hex;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        iconColor: LexorPalette.textSecondary,
        collapsedIconColor: LexorPalette.textSecondary,
        title: const Text(
          'Raw data',
          style: TextStyle(color: LexorPalette.textSecondary, fontSize: 13),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              hex,
              style: const TextStyle(
                color: LexorPalette.textSecondary,
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
