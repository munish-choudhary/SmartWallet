import '../../../core/result/result.dart';
import 'models/dapp_connection.dart';

/// Which sites may see the account, per origin.
abstract interface class DappConnectionRepository {
  Future<Result<DappConnection?>> connectionFor(String origin);
  Future<Result<void>> save(DappConnection connection);
  Future<Result<void>> remove(String origin);
  Future<Result<List<DappConnection>>> all();
}

/// Session-only. Persisting these (and listing them under Settings →
/// Connected Apps) needs the Drift schema, which is a follow-up.
class InMemoryDappConnectionRepository implements DappConnectionRepository {
  final Map<String, DappConnection> _byOrigin = {};

  @override
  Future<Result<DappConnection?>> connectionFor(String origin) async =>
      Result.ok(_byOrigin[origin]);

  @override
  Future<Result<void>> save(DappConnection connection) async {
    _byOrigin[connection.origin] = connection;
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> remove(String origin) async {
    _byOrigin.remove(origin);
    return const Result.ok(null);
  }

  @override
  Future<Result<List<DappConnection>>> all() async =>
      Result.ok(List.unmodifiable(_byOrigin.values));
}
