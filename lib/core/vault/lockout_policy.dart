/// Persists the failed-attempt counter and lockout state. Backed by
/// `flutter_secure_storage` in production; an in-memory fake is used in
/// tests. Never store the PIN itself here — only counters/timestamps.
abstract interface class LockoutStore {
  Future<int> getFailureCount();
  Future<void> setFailureCount(int count);

  Future<int> getLockoutTierIndex();
  Future<void> setLockoutTierIndex(int index);

  Future<DateTime?> getLockedUntil();
  Future<void> setLockedUntil(DateTime? until);
}

final class InMemoryLockoutStore implements LockoutStore {
  int _failureCount = 0;
  int _tierIndex = 0;
  DateTime? _lockedUntil;

  @override
  Future<int> getFailureCount() async => _failureCount;

  @override
  Future<void> setFailureCount(int count) async => _failureCount = count;

  @override
  Future<int> getLockoutTierIndex() async => _tierIndex;

  @override
  Future<void> setLockoutTierIndex(int index) async => _tierIndex = index;

  @override
  Future<DateTime?> getLockedUntil() async => _lockedUntil;

  @override
  Future<void> setLockedUntil(DateTime? until) async => _lockedUntil = until;
}

/// 5 failures -> 1 min lockout. Each subsequent 5 failures escalates:
/// 1 -> 15 -> 60 minutes, then stays at 60.
const List<Duration> _lockoutTiers = [
  Duration(minutes: 1),
  Duration(minutes: 15),
  Duration(minutes: 60),
];

const int _failuresPerTier = 5;

/// Result of recording a failed unlock attempt.
final class LockoutOutcome {
  const LockoutOutcome({required this.lockedUntil});
  final DateTime? lockedUntil;

  bool get isLockedOut => lockedUntil != null;
}

/// Implements CLAUDE.md's PIN Rules lockout/backoff. Stateless aside from
/// [store] — safe to construct fresh each time.
final class LockoutPolicy {
  const LockoutPolicy(this.store, {this.now = DateTime.now});

  final LockoutStore store;
  final DateTime Function() now;

  /// `null` if not currently locked out, otherwise the remaining duration.
  Future<Duration?> remainingLockout() async {
    final lockedUntil = await store.getLockedUntil();
    if (lockedUntil == null) return null;
    final remaining = lockedUntil.difference(now());
    if (remaining.isNegative) {
      await store.setLockedUntil(null);
      return null;
    }
    return remaining;
  }

  /// Call after a wrong-PIN unlock attempt. Returns the new lockout state.
  Future<LockoutOutcome> recordFailure() async {
    final count = await store.getFailureCount() + 1;
    await store.setFailureCount(count);

    if (count % _failuresPerTier != 0) {
      return const LockoutOutcome(lockedUntil: null);
    }

    final tierIndex = await store.getLockoutTierIndex();
    final tier = _lockoutTiers[tierIndex.clamp(0, _lockoutTiers.length - 1)];
    final lockedUntil = now().add(tier);
    await store.setLockedUntil(lockedUntil);
    if (tierIndex < _lockoutTiers.length - 1) {
      await store.setLockoutTierIndex(tierIndex + 1);
    }
    return LockoutOutcome(lockedUntil: lockedUntil);
  }

  /// Call after a successful unlock. Resets failure count and lockout
  /// timer, but keeps the escalation tier — CLAUDE.md doesn't specify
  /// tier reset, so this errs conservative (repeat offenders keep
  /// escalating backoff even across successful unlocks in between).
  Future<void> recordSuccess() async {
    await store.setFailureCount(0);
    await store.setLockedUntil(null);
  }
}
