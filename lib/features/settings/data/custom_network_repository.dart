import '../../../core/network/rpc_probe_service.dart';
import '../../../core/result/result.dart';
import 'custom_network.dart';

abstract interface class CustomNetworkRepository {
  Future<Result<List<CustomNetwork>>> getAll();

  /// Asks the endpoint for its chain ID and measures latency.
  Future<Result<RpcProbe>> probeRpc(Uri rpcUrl);

  /// `Err(duplicateNetwork)` if the same chain ID + RPC URL is already saved.
  Future<Result<void>> add(CustomNetwork network);
}

/// Session-only implementation. Persisting to Drift, and having the chain
/// adapters pick these networks up, is a follow-up: neither exists yet.
class InMemoryCustomNetworkRepository implements CustomNetworkRepository {
  InMemoryCustomNetworkRepository({required RpcProbeService probeService})
      : _probeService = probeService;

  final RpcProbeService _probeService;
  final List<CustomNetwork> _networks = [];

  @override
  Future<Result<List<CustomNetwork>>> getAll() async =>
      Result.ok(List.unmodifiable(_networks));

  @override
  Future<Result<RpcProbe>> probeRpc(Uri rpcUrl) => _probeService.probe(rpcUrl);

  @override
  Future<Result<void>> add(CustomNetwork network) async {
    final exists = _networks.any(
      (n) => n.chainId == network.chainId && n.rpcUrl == network.rpcUrl,
    );
    if (exists) return const Result.err(AppFailure.duplicateNetwork());
    _networks.add(network);
    return const Result.ok(null);
  }
}
