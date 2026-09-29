import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../view_model/pin_setup_cubit.dart';
import 'pin_screen.dart';

class CreatePinScreen extends StatelessWidget {
  const CreatePinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PinScreen(
      step: PinStep.create,
      onBack: () => context.pop(),
      onCompleted: () => context.push(Routes.confirmPin),
      onTooManyMismatches: () {}, // not reachable on the create step
    );
  }
}
