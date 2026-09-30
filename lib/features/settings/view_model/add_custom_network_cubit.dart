import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/rpc_probe_service.dart';
import '../../../core/result/result.dart';
import '../data/custom_network_repository.dart';
import '../data/network_draft.dart';
import '../data/network_preset.dart';
import 'add_custom_network_state.dart';

class AddCustomNetworkCubit extends Cubit<AddCustomNetworkState> {
  AddCustomNetworkCubit({required CustomNetworkRepository repository})
      : _repository = repository,
        super(const AddCustomNetworkState.editing());

  final CustomNetworkRepository _repository;

  /// Fills the whole form from [preset] and tests its endpoint.
  Future<void> selectPreset(NetworkPreset preset) async {
    final s = state;
    if (s is! AddNetworkEditing || s.save is SaveInProgress) return;
    emit(
      AddNetworkEditing(
        draft: NetworkDraft(
          name: preset.name,
          rpcUrl: preset.rpcUrl,
          chainId: '${preset.chainId}',
          symbol: preset.currencySymbol,
          explorerUrl: preset.explorerUrl,
        ),
        preset: preset,
      ),
    );
    await checkRpc();
  }

  void nameChanged(String value) => _edit(
        NetworkField.name,
        (d) => d.copyWith(name: value),
      );

  /// A new URL invalidates the last probe and anything derived from it.
  void rpcUrlChanged(String value) => _edit(
        NetworkField.rpcUrl,
        (d) => d.copyWith(rpcUrl: value),
        resetRpc: true,
      );

  void chainIdChanged(String value) => _edit(
        NetworkField.chainId,
        (d) => d.copyWith(chainId: value),
      );

  void symbolChanged(String value) => _edit(
        NetworkField.symbol,
        (d) => d.copyWith(symbol: value),
      );

  void explorerUrlChanged(String value) => _edit(
        NetworkField.explorerUrl,
        (d) => d.copyWith(explorerUrl: value),
      );

  void _edit(
    NetworkField field,
    NetworkDraft Function(NetworkDraft draft) update, {
    bool resetRpc = false,
  }) {
    final s = state;
    if (s is! AddNetworkEditing || s.save is SaveInProgress) return;
    final errors = {...s.errors}..remove(field);
    // A chain-ID mismatch was measured against the old RPC/chain ID pair;
    // editing either one makes it stale.
    if (field == NetworkField.rpcUrl || field == NetworkField.chainId) {
      errors.remove(NetworkField.chainId);
    }
    emit(
      s.copyWith(
        draft: update(s.draft),
        preset: null,
        rpc: resetRpc ? const RpcCheck.idle() : s.rpc,
        errors: errors,
        save: const SaveStatus.idle(),
      ),
    );
  }

  /// Tests the typed RPC URL. Without [force] this only runs when the URL
  /// hasn't been tested yet, so moving focus in and out of the field is free.
  Future<void> checkRpc({bool force = false}) async {
    final s = state;
    if (s is! AddNetworkEditing || s.save is SaveInProgress) return;
    if (!force && s.rpc is! RpcIdle) return;
    final raw = s.draft.rpcUrl.trim();
    if (raw.isEmpty) return;

    final error = NetworkDraft.validateUrl(raw);
    if (error != null) {
      emit(
        s.copyWith(
          rpc: const RpcCheck.idle(),
          errors: {...s.errors, NetworkField.rpcUrl: error},
        ),
      );
      return;
    }

    emit(s.copyWith(rpc: const RpcCheck.checking()));
    final result = await _repository.probeRpc(Uri.parse(raw));

    final current = state;
    // The user may have left, or typed a different URL while we waited.
    if (isClosed || current is! AddNetworkEditing) return;
    if (current.draft.rpcUrl.trim() != raw) return;
    emit(current.copyWith(rpc: _toCheck(result)));
  }

  /// Validates, re-probes the endpoint to confirm the chain ID, then saves.
  Future<void> submit() async {
    final s = state;
    if (s is! AddNetworkEditing || s.save is SaveInProgress) return;

    final errors = s.draft.validate();
    final network = s.draft.toNetwork();
    if (network == null) {
      emit(s.copyWith(errors: errors, save: const SaveStatus.idle()));
      return;
    }

    emit(
      s.copyWith(
        errors: const {},
        rpc: const RpcCheck.checking(),
        save: const SaveStatus.saving(),
      ),
    );

    final probed = await _repository.probeRpc(network.rpcUrl);
    if (isClosed) return;
    final afterProbe = state;
    if (afterProbe is! AddNetworkEditing) return;

    final RpcProbe probe;
    switch (probed) {
      case Ok(:final value):
        probe = value;
      case Err(:final failure):
        emit(
          afterProbe.copyWith(
            rpc: RpcCheck.failed(failure),
            save: SaveStatus.failed(failure),
          ),
        );
        return;
    }

    // Saving a chain ID the endpoint doesn't serve would let it pass for a
    // different network, so a mismatch blocks the save.
    if (probe.chainId != network.chainId) {
      emit(
        afterProbe.copyWith(
          rpc: RpcCheck.reachable(
            latency: probe.latency,
            chainId: probe.chainId,
          ),
          errors: {NetworkField.chainId: NetworkFieldError.chainIdMismatch},
          save: const SaveStatus.idle(),
        ),
      );
      return;
    }

    final added = await _repository.add(network);
    if (isClosed) return;
    final afterAdd = state;
    if (afterAdd is! AddNetworkEditing) return;
    switch (added) {
      case Ok():
        emit(AddCustomNetworkState.saved(network));
      case Err(:final failure):
        emit(
          afterAdd.copyWith(
            rpc: RpcCheck.reachable(
              latency: probe.latency,
              chainId: probe.chainId,
            ),
            save: SaveStatus.failed(failure),
          ),
        );
    }
  }

  static RpcCheck _toCheck(Result<RpcProbe> result) => switch (result) {
        Ok(:final value) =>
          RpcCheck.reachable(latency: value.latency, chainId: value.chainId),
        Err(:final failure) => RpcCheck.failed(failure),
      };
}
