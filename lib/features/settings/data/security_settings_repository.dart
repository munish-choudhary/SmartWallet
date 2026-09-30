import '../../../core/result/result.dart';
import 'auto_lock_option.dart';

abstract interface class SecuritySettingsRepository {
  Future<Result<AutoLockOption>> getAutoLock();
  Future<Result<void>> setAutoLock(AutoLockOption option);

  Future<Result<bool>> getHideBalances();
  Future<Result<void>> setHideBalances(bool hide);
}

/// Session-only implementation. Persisting the value (and having
/// `VaultSession` honour it) is a follow-up that touches `core/vault/`,
/// which needs sign-off first.
class InMemorySecuritySettingsRepository implements SecuritySettingsRepository {
  AutoLockOption _autoLock = AutoLockOption.oneMinute;
  bool _hideBalances = false;

  @override
  Future<Result<AutoLockOption>> getAutoLock() async => Result.ok(_autoLock);

  @override
  Future<Result<void>> setAutoLock(AutoLockOption option) async {
    _autoLock = option;
    return const Result.ok(null);
  }

  @override
  Future<Result<bool>> getHideBalances() async => Result.ok(_hideBalances);

  @override
  Future<Result<void>> setHideBalances(bool hide) async {
    _hideBalances = hide;
    return const Result.ok(null);
  }
}
