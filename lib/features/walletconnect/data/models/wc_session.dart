import 'package:freezed_annotation/freezed_annotation.dart';

import 'wc_chain.dart';
import 'wc_dapp.dart';

part 'wc_session.freezed.dart';

/// What a connected dApp is allowed to ask for. Note [sendTransactions]
/// and [signMessages] only let the dApp *request* — each one still needs
/// the user's explicit approval on a review screen.
enum WcPermission {
  viewAccount,
  sendTransactions,
  signMessages,
  signTypedData,
}

@freezed
sealed class WcSession with _$WcSession {
  const WcSession._();

  const factory WcSession({
    /// WalletConnect session topic — a public identifier, safe in a route path.
    required String topic,
    required WcDapp dapp,
    required String accountAddress,
    required String accountLabel,
    required List<WcChain> chains,
    required List<WcPermission> permissions,
    required DateTime connectedAt,
    required DateTime expiresAt,
    required DateTime lastActivityAt,
    @Default('Session created') String lastActivityLabel,
  }) = _WcSession;

  String get shortAddress => shortenAddress(accountAddress);
}

/// `0x71C7...976F`
String shortenAddress(String address, {int head = 6, int tail = 4}) {
  if (address.length <= head + tail + 3) return address;
  return '${address.substring(0, head)}...${address.substring(address.length - tail)}';
}
