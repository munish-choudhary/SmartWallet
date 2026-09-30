import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/network/rpc_probe_service.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/settings/data/custom_network.dart';
import 'package:smart_wallet/features/settings/data/network_draft.dart';
import 'package:smart_wallet/features/settings/data/network_preset.dart';
import 'package:smart_wallet/features/settings/view_model/add_custom_network_cubit.dart';
import 'package:smart_wallet/features/settings/view_model/add_custom_network_state.dart';

import 'fake_custom_network_repository.dart';

const _polygonDraft = NetworkDraft(
  name: 'Polygon Relay',
  rpcUrl: 'https://rpc.example.com',
  chainId: '137',
  symbol: 'pol',
);

final _polygonNetwork = CustomNetwork(
  name: 'Polygon Relay',
  rpcUrl: Uri.parse('https://rpc.example.com'),
  chainId: 137,
  currencySymbol: 'POL',
);

const _reachable137 = RpcCheck.reachable(
  latency: Duration(milliseconds: 42),
  chainId: 137,
);

AddNetworkEditing _editing({
  NetworkDraft draft = const NetworkDraft(),
  NetworkPreset? preset,
  RpcCheck rpc = const RpcCheck.idle(),
  Map<NetworkField, NetworkFieldError> errors = const {},
  SaveStatus save = const SaveStatus.idle(),
}) =>
    AddNetworkEditing(
      draft: draft,
      preset: preset,
      rpc: rpc,
      errors: errors,
      save: save,
    );

void main() {
  late FakeCustomNetworkRepository repo;

  setUp(() => repo = FakeCustomNetworkRepository());

  AddCustomNetworkCubit build() => AddCustomNetworkCubit(repository: repo);

  group('presets', () {
    final base = NetworkPreset.all.firstWhere((p) => p.label == 'Base');
    final baseDraft = NetworkDraft(
      name: base.name,
      rpcUrl: base.rpcUrl,
      chainId: '${base.chainId}',
      symbol: base.currencySymbol,
      explorerUrl: base.explorerUrl,
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'fills every field, then tests the endpoint',
      build: build,
      setUp: () => repo.probeResult = const Result.ok(
        RpcProbe(latency: Duration(milliseconds: 42), chainId: 8453),
      ),
      act: (c) => c.selectPreset(base),
      expect: () => [
        _editing(draft: baseDraft, preset: base),
        _editing(
          draft: baseDraft,
          preset: base,
          rpc: const RpcCheck.checking(),
        ),
        _editing(
          draft: baseDraft,
          preset: base,
          rpc: const RpcCheck.reachable(
            latency: Duration(milliseconds: 42),
            chainId: 8453,
          ),
        ),
      ],
      verify: (_) => expect(repo.probed, [Uri.parse(base.rpcUrl)]),
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'replaces earlier input and errors',
      build: build,
      seed: () => _editing(
        draft: _polygonDraft,
        errors: {NetworkField.name: NetworkFieldError.tooLong},
      ),
      act: (c) => c.selectPreset(base),
      skip: 1,
      expect: () => [
        _editing(
          draft: baseDraft,
          preset: base,
          rpc: const RpcCheck.checking(),
        ),
        isA<AddNetworkEditing>()
            .having((s) => s.errors, 'errors', isEmpty)
            .having((s) => s.draft, 'draft', baseDraft),
      ],
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'editing any field afterwards makes it a custom network again',
      build: build,
      act: (c) async {
        await c.selectPreset(base);
        c.nameChanged('My Base');
      },
      verify: (c) {
        final s = c.state as AddNetworkEditing;
        expect(s.preset, isNull);
        expect(s.draft.name, 'My Base');
        expect(s.draft.chainId, '8453');
      },
    );
  });

  group('editing', () {
    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'clears the error on the field being edited only',
      build: build,
      seed: () => _editing(
        errors: {
          NetworkField.name: NetworkFieldError.required,
          NetworkField.symbol: NetworkFieldError.required,
        },
      ),
      act: (c) => c.nameChanged('Relay'),
      expect: () => [
        _editing(
          draft: const NetworkDraft(name: 'Relay'),
          errors: {NetworkField.symbol: NetworkFieldError.required},
        ),
      ],
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'a new RPC URL discards the previous probe and a stale chain-ID mismatch',
      build: build,
      seed: () => _editing(
        draft: _polygonDraft,
        rpc: const RpcCheck.reachable(
          latency: Duration(milliseconds: 42),
          chainId: 1,
        ),
        errors: {NetworkField.chainId: NetworkFieldError.chainIdMismatch},
      ),
      act: (c) => c.rpcUrlChanged('https://other.example.com'),
      expect: () => [
        _editing(draft: _polygonDraft.copyWith(rpcUrl: 'https://other.example.com')),
      ],
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'editing the chain ID keeps the probe but drops the stale mismatch',
      build: build,
      seed: () => _editing(
        draft: _polygonDraft,
        rpc: _reachable137,
        errors: {NetworkField.chainId: NetworkFieldError.chainIdMismatch},
      ),
      act: (c) => c.chainIdChanged('138'),
      expect: () => [
        _editing(
          draft: _polygonDraft.copyWith(chainId: '138'),
          rpc: _reachable137,
        ),
      ],
    );

    test('chainIdCheck compares the typed ID with what the RPC reported', () {
      expect(_editing().chainIdCheck, ChainIdCheck.unknown);
      expect(
        _editing(draft: _polygonDraft, rpc: _reachable137).chainIdCheck,
        ChainIdCheck.matches,
      );
      expect(
        _editing(
          draft: _polygonDraft.copyWith(chainId: '1'),
          rpc: _reachable137,
        ).chainIdCheck,
        ChainIdCheck.mismatch,
      );
      expect(
        _editing(
          draft: _polygonDraft.copyWith(chainId: 'abc'),
          rpc: _reachable137,
        ).chainIdCheck,
        ChainIdCheck.unknown,
      );
    });
  });

  group('checkRpc', () {
    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'ignores an empty URL',
      build: build,
      act: (c) => c.checkRpc(),
      expect: () => <AddCustomNetworkState>[],
      verify: (_) => expect(repo.probed, isEmpty),
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'flags a malformed URL without sending anything',
      build: build,
      seed: () => _editing(draft: const NetworkDraft(rpcUrl: 'rpc.example.com')),
      act: (c) => c.checkRpc(),
      expect: () => [
        _editing(
          draft: const NetworkDraft(rpcUrl: 'rpc.example.com'),
          errors: {NetworkField.rpcUrl: NetworkFieldError.invalidUrl},
        ),
      ],
      verify: (_) => expect(repo.probed, isEmpty),
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'refuses to probe plain http on a remote host',
      build: build,
      seed: () => _editing(draft: const NetworkDraft(rpcUrl: 'http://rpc.example.com')),
      act: (c) => c.checkRpc(),
      verify: (c) {
        expect(
          (c.state as AddNetworkEditing).errors[NetworkField.rpcUrl],
          NetworkFieldError.insecureUrl,
        );
        expect(repo.probed, isEmpty);
      },
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'records a failed probe',
      build: build,
      setUp: () => repo.probeResult =
          const Result.err(AppFailure.network('Endpoint unreachable')),
      seed: () => _editing(draft: _polygonDraft),
      act: (c) => c.checkRpc(),
      expect: () => [
        _editing(draft: _polygonDraft, rpc: const RpcCheck.checking()),
        _editing(
          draft: _polygonDraft,
          rpc: const RpcCheck.failed(AppFailure.network('Endpoint unreachable')),
        ),
      ],
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'is a no-op once the URL has been tested, unless forced',
      build: build,
      seed: () => _editing(draft: _polygonDraft, rpc: _reachable137),
      act: (c) async {
        await c.checkRpc();
        expect(repo.probed, isEmpty);
        await c.checkRpc(force: true);
      },
      verify: (_) => expect(repo.probed, hasLength(1)),
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'drops a result that arrives after the URL was changed',
      build: build,
      setUp: () => repo.probeGate = Completer<Result<RpcProbe>>(),
      seed: () => _editing(draft: _polygonDraft),
      act: (c) async {
        final pending = c.checkRpc();
        c.rpcUrlChanged('https://other.example.com');
        repo.probeGate!.complete(
          const Result.ok(
            RpcProbe(latency: Duration(milliseconds: 9), chainId: 137),
          ),
        );
        await pending;
      },
      verify: (c) {
        final s = c.state as AddNetworkEditing;
        expect(s.draft.rpcUrl, 'https://other.example.com');
        expect(s.rpc, const RpcCheck.idle());
      },
    );

    test('does not emit after the cubit is closed mid-probe', () async {
      repo.probeGate = Completer<Result<RpcProbe>>();
      final cubit = build()..rpcUrlChanged('https://rpc.example.com');
      final pending = cubit.checkRpc();
      await cubit.close();
      repo.probeGate!.complete(
        const Result.ok(
          RpcProbe(latency: Duration(milliseconds: 9), chainId: 137),
        ),
      );
      await expectLater(pending, completes);
    });
  });

  group('submit', () {
    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'an empty form reports every required field and sends nothing',
      build: build,
      act: (c) => c.submit(),
      expect: () => [
        _editing(
          errors: {
            NetworkField.name: NetworkFieldError.required,
            NetworkField.rpcUrl: NetworkFieldError.required,
            NetworkField.chainId: NetworkFieldError.required,
            NetworkField.symbol: NetworkFieldError.required,
          },
        ),
      ],
      verify: (_) {
        expect(repo.probed, isEmpty);
        expect(repo.added, isEmpty);
      },
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'verifies the chain ID with the RPC, then saves the normalised network',
      build: build,
      setUp: () => repo.probeResult = const Result.ok(
        RpcProbe(latency: Duration(milliseconds: 42), chainId: 137),
      ),
      seed: () => _editing(draft: _polygonDraft),
      act: (c) => c.submit(),
      expect: () => [
        _editing(
          draft: _polygonDraft,
          rpc: const RpcCheck.checking(),
          save: const SaveStatus.saving(),
        ),
        AddNetworkSaved(_polygonNetwork),
      ],
      verify: (_) {
        expect(repo.probed, [Uri.parse('https://rpc.example.com')]);
        expect(repo.added, [_polygonNetwork]);
      },
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'blocks the save when the RPC serves a different chain',
      build: build,
      setUp: () => repo.probeResult = const Result.ok(
        RpcProbe(latency: Duration(milliseconds: 42), chainId: 1),
      ),
      seed: () => _editing(draft: _polygonDraft),
      act: (c) => c.submit(),
      expect: () => [
        _editing(
          draft: _polygonDraft,
          rpc: const RpcCheck.checking(),
          save: const SaveStatus.saving(),
        ),
        _editing(
          draft: _polygonDraft,
          rpc: const RpcCheck.reachable(
            latency: Duration(milliseconds: 42),
            chainId: 1,
          ),
          errors: {NetworkField.chainId: NetworkFieldError.chainIdMismatch},
        ),
      ],
      verify: (_) => expect(repo.added, isEmpty),
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'does not save when the endpoint cannot be reached',
      build: build,
      setUp: () => repo.probeResult =
          const Result.err(AppFailure.network('Endpoint unreachable')),
      seed: () => _editing(draft: _polygonDraft),
      act: (c) => c.submit(),
      expect: () => [
        _editing(
          draft: _polygonDraft,
          rpc: const RpcCheck.checking(),
          save: const SaveStatus.saving(),
        ),
        _editing(
          draft: _polygonDraft,
          rpc: const RpcCheck.failed(AppFailure.network('Endpoint unreachable')),
          save: const SaveStatus.failed(
            AppFailure.network('Endpoint unreachable'),
          ),
        ),
      ],
      verify: (_) => expect(repo.added, isEmpty),
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'surfaces a duplicate and stays on the form',
      build: build,
      setUp: () {
        repo.probeResult = const Result.ok(
          RpcProbe(latency: Duration(milliseconds: 42), chainId: 137),
        );
        repo.addResult = const Result.err(AppFailure.duplicateNetwork());
      },
      seed: () => _editing(draft: _polygonDraft),
      act: (c) => c.submit(),
      expect: () => [
        _editing(
          draft: _polygonDraft,
          rpc: const RpcCheck.checking(),
          save: const SaveStatus.saving(),
        ),
        _editing(
          draft: _polygonDraft,
          rpc: _reachable137,
          save: const SaveStatus.failed(AppFailure.duplicateNetwork()),
        ),
      ],
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'ignores a second tap and any edits while a save is running',
      build: build,
      setUp: () => repo.probeGate = Completer<Result<RpcProbe>>(),
      seed: () => _editing(draft: _polygonDraft),
      act: (c) async {
        final first = c.submit();
        await c.submit();
        c.nameChanged('Changed mid-save');
        await c.selectPreset(NetworkPreset.all.first);
        repo.probeGate!.complete(
          const Result.ok(
            RpcProbe(latency: Duration(milliseconds: 42), chainId: 137),
          ),
        );
        await first;
      },
      verify: (_) {
        expect(repo.probed, hasLength(1));
        expect(repo.added, [_polygonNetwork]);
      },
    );

    blocTest<AddCustomNetworkCubit, AddCustomNetworkState>(
      'editing after a failed save clears the failure',
      build: build,
      seed: () => _editing(
        draft: _polygonDraft,
        save: const SaveStatus.failed(AppFailure.duplicateNetwork()),
      ),
      act: (c) => c.symbolChanged('matic'),
      verify: (c) =>
          expect((c.state as AddNetworkEditing).save, const SaveStatus.idle()),
    );
  });

  group('RpcReachable helpers', () {
    RpcReachable at(int ms) =>
        RpcCheck.reachable(latency: Duration(milliseconds: ms), chainId: 1)
            as RpcReachable;

    test('grades latency', () {
      expect(at(42).grade, LatencyGrade.fast);
      expect(at(150).grade, LatencyGrade.fast);
      expect(at(151).grade, LatencyGrade.good);
      expect(at(500).grade, LatencyGrade.good);
      expect(at(501).grade, LatencyGrade.slow);
    });

    test('bar fill shrinks with latency and stays within 5%..100%', () {
      expect(at(0).barFill, 1.0);
      expect(at(250).barFill, closeTo(0.75, 1e-9));
      expect(at(5000).barFill, 0.05);
    });
  });
}
