import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet/features/settings/data/security_settings_repository.dart';
import 'package:smart_wallet/features/settings/view_model/balance_privacy_cubit.dart';
import 'package:smart_wallet/features/settings/view_model/balance_privacy_state.dart';

void main() {
  blocTest<BalancePrivacyCubit, BalancePrivacyState>(
    'loads the default and persists a toggle',
    build: () => BalancePrivacyCubit(
      repository: InMemorySecuritySettingsRepository(),
    ),
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero);
      await cubit.setHideBalances(true);
    },
    expect: () => const [
      BalancePrivacyState.ready(hideBalances: false),
      BalancePrivacyState.ready(hideBalances: true),
    ],
  );
}
