import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/result/result.dart';
import 'package:smart_wallet/features/settings/data/wallet_profile.dart';
import 'package:smart_wallet/features/settings/data/wallet_profile_repository.dart';
import 'package:smart_wallet/features/settings/view_model/wallets_cubit.dart';
import 'package:smart_wallet/features/settings/view_model/wallets_state.dart';

const _a = WalletProfile(walletId: 'a', name: 'My Wallet', address: '0xAAA');
const _b = WalletProfile(walletId: 'b', name: 'Wallet 2', address: '0xBBB');

class _Profiles implements WalletProfileRepository {
  String active = 'a';
  AppFailure? loadFailure;
  AppFailure? switchFailure;

  @override
  Future<Result<WalletRoster>> loadAll() async {
    final failure = loadFailure;
    if (failure != null) return Result.err(failure);
    return Result.ok(WalletRoster(wallets: [_a, _b], activeId: active));
  }

  @override
  Future<Result<void>> switchTo(String walletId) async {
    final failure = switchFailure;
    if (failure != null) return Result.err(failure);
    active = walletId;
    return const Result.ok(null);
  }

  @override
  Future<Result<WalletProfile>> load() async => const Result.ok(_a);

  @override
  Future<Result<void>> rename(String name) async => const Result.ok(null);
}

void main() {
  late _Profiles profiles;

  setUp(() => profiles = _Profiles());

  blocTest<WalletsCubit, WalletsState>(
    'loads every wallet with the active one marked',
    build: () => WalletsCubit(profiles: profiles),
    expect: () => [
      const WalletsState.loaded([_a, _b], activeId: 'a'),
    ],
  );

  blocTest<WalletsCubit, WalletsState>(
    'emits failure when the wallets cannot be loaded',
    setUp: () => profiles.loadFailure = const AppFailure.walletNotFound(),
    build: () => WalletsCubit(profiles: profiles),
    expect: () => [const WalletsState.failure(AppFailure.walletNotFound())],
  );

  blocTest<WalletsCubit, WalletsState>(
    'select switches the active wallet',
    build: () => WalletsCubit(profiles: profiles),
    skip: 1,
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero); // initial load
      await cubit.select('b');
    },
    expect: () => [
      const WalletsState.loaded([_a, _b], activeId: 'a', switchingTo: 'b'),
      const WalletsState.loaded([_a, _b], activeId: 'b'),
    ],
    verify: (_) => expect(profiles.active, 'b'),
  );

  blocTest<WalletsCubit, WalletsState>(
    'select keeps the current wallet when switching fails',
    setUp: () => profiles.switchFailure = const AppFailure.walletNotFound(),
    build: () => WalletsCubit(profiles: profiles),
    skip: 1,
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero); // initial load
      await cubit.select('b');
    },
    expect: () => [
      const WalletsState.loaded([_a, _b], activeId: 'a', switchingTo: 'b'),
      const WalletsState.loaded([_a, _b], activeId: 'a'),
    ],
  );

  blocTest<WalletsCubit, WalletsState>(
    'select on the already-active wallet does nothing',
    build: () => WalletsCubit(profiles: profiles),
    skip: 1,
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero); // initial load
      await cubit.select('a');
    },
    expect: () => <WalletsState>[],
  );
}
