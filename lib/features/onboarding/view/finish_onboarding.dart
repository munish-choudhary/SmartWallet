import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../data/add_wallet_gate.dart';
import '../view_model/onboarding_flow_cubit.dart';

/// The success screens' "Go to wallet" action. First-run onboarding lands
/// on the portfolio; adding a wallet makes the new one active and returns
/// to the Wallets screen.
Future<void> finishOnboarding(BuildContext context) async {
  final flow = context.read<OnboardingFlowCubit>();
  final router = GoRouter.of(context);
  if (flow.state.addingWallet) {
    await flow.activateCompletedWallet();
    if (!context.mounted) return;
    context.read<AddWalletGate>().close();
    flow.reset();
    router.go(Routes.wallets);
    return;
  }
  flow.reset();
  router.go(Routes.portfolio);
}
