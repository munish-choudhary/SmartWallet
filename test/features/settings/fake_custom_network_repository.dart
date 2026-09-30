import 'dart:async';

import 'package:smart_wallet/core/network/rpc_probe_service.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/settings/data/custom_network.dart';
import 'package:smart_wallet/features/settings/data/custom_network_repository.dart';

/// Scriptable [CustomNetworkRepository]: no network, and each call's result
/// is set by the test. Records what it was asked to do.
class FakeCustomNetworkRepository implements CustomNetworkRepository {
  Result<RpcProbe> probeResult = const Result.ok(
    RpcProbe(latency: Duration(milliseconds: 42), chainId: 1),
  );
  Result<void> addResult = const Result.ok(null);

  /// When set, [probeRpc] waits on it instead of answering immediately, so a
  /// test can change the form while a probe is in flight.
  Completer<Result<RpcProbe>>? probeGate;

  final probed = <Uri>[];
  final added = <CustomNetwork>[];

  @override
  Future<Result<List<CustomNetwork>>> getAll() async =>
      Result.ok(List.unmodifiable(added));

  @override
  Future<Result<RpcProbe>> probeRpc(Uri rpcUrl) {
    probed.add(rpcUrl);
    return probeGate?.future ?? Future.value(probeResult);
  }

  @override
  Future<Result<void>> add(CustomNetwork network) async {
    if (addResult.isOk) added.add(network);
    return addResult;
  }
}
