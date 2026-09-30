import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../view_model/onboarding_flow_cubit.dart';

extension PinEntryNavigation on BuildContext {
  /// Goes to the PIN step of the running flow: creating a new PIN during
  /// onboarding, or proving the existing one when adding another wallet.
  void pushPinEntry() {
    final adding = read<OnboardingFlowCubit>().state.addingWallet;
    push(adding ? Routes.verifyPin : Routes.createPin);
  }
}
