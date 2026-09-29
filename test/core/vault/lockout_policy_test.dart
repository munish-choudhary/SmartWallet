import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/core/vault/lockout_policy.dart';

void main() {
  group('LockoutPolicy', () {
    test('no lockout before 5 failures', () async {
      final now = DateTime(2026, 1, 1);
      final policy = LockoutPolicy(InMemoryLockoutStore(), now: () => now);

      for (var i = 0; i < 4; i++) {
        final outcome = await policy.recordFailure();
        expect(outcome.isLockedOut, isFalse);
      }
      expect(await policy.remainingLockout(), isNull);
    });

    test('escalates 1 -> 15 -> 60 minutes across repeated lockouts',
        () async {
      var now = DateTime(2026, 1, 1);
      final policy = LockoutPolicy(InMemoryLockoutStore(), now: () => now);

      Future<Duration> lockOutOnce() async {
        LockoutOutcome outcome = const LockoutOutcome(lockedUntil: null);
        for (var i = 0; i < 5; i++) {
          outcome = await policy.recordFailure();
        }
        final until = outcome.lockedUntil!;
        return until.difference(now);
      }

      expect(await lockOutOnce(), const Duration(minutes: 1));
      now = now.add(const Duration(minutes: 1, seconds: 1));

      expect(await lockOutOnce(), const Duration(minutes: 15));
      now = now.add(const Duration(minutes: 15, seconds: 1));

      expect(await lockOutOnce(), const Duration(minutes: 60));
      now = now.add(const Duration(minutes: 60, seconds: 1));

      // Stays at 60 minutes for further lockouts.
      expect(await lockOutOnce(), const Duration(minutes: 60));
    });

    test('recordSuccess clears the failure count and any active lockout',
        () async {
      final now = DateTime(2026, 1, 1);
      final policy = LockoutPolicy(InMemoryLockoutStore(), now: () => now);

      for (var i = 0; i < 5; i++) {
        await policy.recordFailure();
      }
      expect(await policy.remainingLockout(), isNotNull);

      await policy.recordSuccess();
      expect(await policy.remainingLockout(), isNull);
    });

    test('remainingLockout expires on its own once time passes', () async {
      var now = DateTime(2026, 1, 1);
      final policy = LockoutPolicy(InMemoryLockoutStore(), now: () => now);

      for (var i = 0; i < 5; i++) {
        await policy.recordFailure();
      }
      expect(await policy.remainingLockout(), const Duration(minutes: 1));

      now = now.add(const Duration(minutes: 1, seconds: 1));
      expect(await policy.remainingLockout(), isNull);
    });
  });
}
