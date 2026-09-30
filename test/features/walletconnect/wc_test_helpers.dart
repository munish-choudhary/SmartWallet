import 'package:smart_wallet/features/walletconnect/data/in_memory_wallet_connect_repository.dart';
import 'package:smart_wallet/features/walletconnect/data/wallet_account_source.dart';

/// A structurally valid pairing link; [seed] varies the topic so each
/// call is a different pairing.
String validPairingLink({int seed = 0, String extra = ''}) {
  final topic = seed.toRadixString(16).padLeft(64, '0');
  final key = 'ab12' * 16;
  return 'wc:$topic@2?relay-protocol=irn&symKey=$key$extra';
}

final testNow = DateTime.utc(2026, 9, 30, 12);

InMemoryWalletConnectRepository buildRepository({
  bool seedSessions = true,
  Duration latency = Duration.zero,
  DateTime Function()? now,
}) {
  return InMemoryWalletConnectRepository(
    accountSource: const InMemoryWalletAccountSource(),
    latency: latency,
    seedSessions: seedSessions,
    now: now ?? () => testNow,
  );
}
