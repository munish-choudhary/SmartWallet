import 'wc_chain.dart';
import 'wc_dapp.dart';

/// Where a signing request came from — drives the source badge on the
/// review sheet (CLAUDE.md: "<dApp> via WalletConnect").
enum WcRequestOrigin { walletConnect, inAppBrowser }

/// A request from a dApp that needs an explicit user decision. Every
/// subtype is rendered by a review sheet; there is no path that signs
/// without showing one.
///
/// All display strings are prepared *before* the request reaches the UI
/// (decoded, formatted), so the sheets stay dumb. Anything originating from
/// the dApp (messages, typed-data labels) is untrusted text.
sealed class WcRequest {
  const WcRequest({
    required this.id,
    required this.dapp,
    required this.chain,
    required this.signer,
    required this.receivedAt,
    this.origin = WcRequestOrigin.walletConnect,
  });

  final String id;
  final WcDapp dapp;
  final WcChain chain;

  /// Address of the account that would sign.
  final String signer;
  final DateTime receivedAt;
  final WcRequestOrigin origin;
}

/// `personal_sign`
final class WcPersonalSignRequest extends WcRequest {
  const WcPersonalSignRequest({
    required super.id,
    required super.dapp,
    required super.chain,
    required super.signer,
    required super.receivedAt,
    super.origin,
    required this.message,
    this.messageIsReadable = true,
  });

  /// The message as text, or the raw hex when it isn't valid UTF-8.
  final String message;
  final bool messageIsReadable;
}

/// `eth_signTypedData_v4`
final class WcTypedDataRequest extends WcRequest {
  const WcTypedDataRequest({
    required super.id,
    required super.dapp,
    required super.chain,
    required super.signer,
    required super.receivedAt,
    super.origin,
    required this.primaryType,
    required this.domain,
    required this.fields,
    this.authorizesTransfers = false,
  });

  final String primaryType;

  /// Domain entries, e.g. `name`, `verifyingContract`, `chainId`.
  final List<WcTypedField> domain;

  /// Flattened message contents, in declaration order.
  final List<WcTypedField> fields;

  /// True for Permit/Permit2/Order-style messages that can move funds
  /// without a transaction — the sheet shows a prominent warning.
  final bool authorizesTransfers;
}

final class WcTypedField {
  const WcTypedField(this.label, this.value, {this.depth = 0});

  final String label;
  final String value;

  /// Nesting level for struct members (indented in the UI).
  final int depth;
}

/// `eth_sendTransaction`
final class WcTransactionRequest extends WcRequest {
  const WcTransactionRequest({
    required super.id,
    required super.dapp,
    required super.chain,
    required super.signer,
    required super.receivedAt,
    super.origin,
    required this.to,
    required this.valueDisplay,
    required this.networkFeeDisplay,
    this.valueUsd,
    this.networkFeeUsd,
    this.methodName,
    this.dataHex,
    this.balanceChanges = const [],
    this.approval,
    this.risks = const [],
  });

  final String to;

  /// `0.25 ETH` — `0 ETH` for pure contract calls.
  final String valueDisplay;
  final double? valueUsd;
  final String networkFeeDisplay;
  final double? networkFeeUsd;

  /// Decoded locally from the selector (`approve`, `swapExactETHForTokens`…);
  /// null when unknown — never taken from the dApp.
  final String? methodName;
  final String? dataHex;

  /// Result of the pre-sign simulation, when available.
  final List<WcBalanceChange> balanceChanges;

  /// Set when the transaction is an ERC-20 approval.
  final WcTokenApproval? approval;
  final List<WcRiskFlag> risks;

  bool get isContractCall => dataHex != null && dataHex != '0x';
}

final class WcBalanceChange {
  const WcBalanceChange({
    required this.symbol,
    required this.amountDisplay,
    required this.isOutgoing,
  });

  final String symbol;
  final String amountDisplay;
  final bool isOutgoing;
}

/// ERC-20 `approve`. Unlimited approvals must show a warning and an
/// editable spending cap (CLAUDE.md, Signing Pipeline).
final class WcTokenApproval {
  const WcTokenApproval({
    required this.tokenSymbol,
    required this.spender,
    required this.requestedAmountDisplay,
    required this.isUnlimited,
  });

  final String tokenSymbol;
  final String spender;
  final String requestedAmountDisplay;
  final bool isUnlimited;
}

enum WcRiskSeverity { caution, danger }

final class WcRiskFlag {
  const WcRiskFlag({
    required this.severity,
    required this.title,
    required this.detail,
  });

  final WcRiskSeverity severity;
  final String title;
  final String detail;
}

/// What the user chose on a review sheet.
final class WcRequestDecision {
  const WcRequestDecision.approve({this.approvalCap}) : approved = true;
  const WcRequestDecision.reject()
      : approved = false,
        approvalCap = null;

  final bool approved;

  /// User-edited spending cap for token approvals (display string as typed).
  final String? approvalCap;
}
