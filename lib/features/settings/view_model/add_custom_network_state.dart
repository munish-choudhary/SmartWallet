import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/result/result.dart';
import '../data/custom_network.dart';
import '../data/network_draft.dart';
import '../data/network_preset.dart';

part 'add_custom_network_state.freezed.dart';

/// Outcome of the latest reachability / chain-ID probe of the typed RPC URL.
@freezed
sealed class RpcCheck with _$RpcCheck {
  const factory RpcCheck.idle() = RpcIdle;
  const factory RpcCheck.checking() = RpcChecking;
  const factory RpcCheck.reachable({
    required Duration latency,
    required int chainId,
  }) = RpcReachable;
  const factory RpcCheck.failed(AppFailure failure) = RpcFailed;
}

enum LatencyGrade { fast, good, slow }

extension RpcReachableX on RpcReachable {
  LatencyGrade get grade {
    final ms = latency.inMilliseconds;
    if (ms <= 150) return LatencyGrade.fast;
    if (ms <= 500) return LatencyGrade.good;
    return LatencyGrade.slow;
  }

  /// 0..1 fill for the latency bar; lower latency fills more of it.
  double get barFill => (1 - latency.inMilliseconds / 1000).clamp(0.05, 1.0);
}

/// Progress of the "Verify & Save" action.
@freezed
sealed class SaveStatus with _$SaveStatus {
  const factory SaveStatus.idle() = SaveIdle;
  const factory SaveStatus.saving() = SaveInProgress;
  const factory SaveStatus.failed(AppFailure failure) = SaveFailed;
}

enum ChainIdCheck { unknown, matches, mismatch }

@freezed
sealed class AddCustomNetworkState with _$AddCustomNetworkState {
  const factory AddCustomNetworkState.editing({
    @Default(NetworkDraft()) NetworkDraft draft,

    /// Set while the form still holds exactly what a preset filled in.
    NetworkPreset? preset,
    @Default(RpcCheck.idle()) RpcCheck rpc,
    @Default(<NetworkField, NetworkFieldError>{})
    Map<NetworkField, NetworkFieldError> errors,
    @Default(SaveStatus.idle()) SaveStatus save,
  }) = AddNetworkEditing;

  const factory AddCustomNetworkState.saved(CustomNetwork network) =
      AddNetworkSaved;
}

extension AddNetworkEditingX on AddNetworkEditing {
  /// Whether the typed chain ID agrees with what the RPC reported.
  ChainIdCheck get chainIdCheck {
    final probe = rpc;
    final typed = int.tryParse(draft.chainId.trim());
    if (probe is! RpcReachable || typed == null) return ChainIdCheck.unknown;
    return probe.chainId == typed ? ChainIdCheck.matches : ChainIdCheck.mismatch;
  }
}
