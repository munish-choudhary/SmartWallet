import 'package:flutter/material.dart';

import '../../data/models/wc_session.dart';

extension WcPermissionInfo on WcPermission {
  IconData get icon => switch (this) {
        WcPermission.viewAccount => Icons.visibility_outlined,
        WcPermission.sendTransactions => Icons.receipt_long_outlined,
        WcPermission.signMessages => Icons.draw_outlined,
        WcPermission.signTypedData => Icons.fact_check_outlined,
      };

  /// What the permission allows, in plain language. Always makes clear the
  /// dApp can only *ask* — the user approves each action.
  String get description => switch (this) {
        WcPermission.viewAccount =>
          'View your wallet address and public balances on authorized networks.',
        WcPermission.sendTransactions =>
          'Request transaction approvals. Nothing is sent until you confirm it.',
        WcPermission.signMessages =>
          'Request message signatures for sign-in. You review each request.',
        WcPermission.signTypedData =>
          'Request structured data signatures (orders, permits). You review each one.',
      };
}
