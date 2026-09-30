import 'package:flutter/material.dart';

import '../../data/models/wc_request.dart';
import 'sign_message_sheet.dart';
import 'sign_typed_data_sheet.dart';
import 'transaction_request_sheet.dart';

/// Picks the review sheet for [request]'s type. There is deliberately no
/// default branch: a new request type can't be added without a sheet.
Widget buildRequestSheet(
  WcRequest request, {
  required ValueChanged<WcRequestDecision> onDecision,
  bool busy = false,
  int queued = 0,
}) {
  const reject = WcRequestDecision.reject();
  return switch (request) {
    WcPersonalSignRequest() => SignMessageSheet(
        key: ValueKey(request.id),
        request: request,
        busy: busy,
        queued: queued,
        onApprove: () => onDecision(const WcRequestDecision.approve()),
        onReject: () => onDecision(reject),
      ),
    WcTypedDataRequest() => SignTypedDataSheet(
        key: ValueKey(request.id),
        request: request,
        busy: busy,
        queued: queued,
        onApprove: () => onDecision(const WcRequestDecision.approve()),
        onReject: () => onDecision(reject),
      ),
    WcTransactionRequest() => TransactionRequestSheet(
        key: ValueKey(request.id),
        request: request,
        busy: busy,
        queued: queued,
        onApprove: (cap) =>
            onDecision(WcRequestDecision.approve(approvalCap: cap)),
        onReject: () => onDecision(reject),
      ),
  };
}

/// One-shot review used outside the WalletConnect queue (the in-app
/// browser). Resolves with the user's decision; dismissing the sheet —
/// barrier tap or swipe — is a rejection.
Future<WcRequestDecision> showRequestReviewSheet(
  BuildContext context,
  WcRequest request,
) async {
  final decision = await showModalBottomSheet<WcRequestDecision>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: buildRequestSheet(
        request,
        onDecision: (d) => Navigator.of(sheetContext).pop(d),
      ),
    ),
  );
  return decision ?? const WcRequestDecision.reject();
}
