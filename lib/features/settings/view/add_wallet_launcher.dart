import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../onboarding/data/add_wallet_gate.dart';

/// Starts the add-another-wallet flow (create or import) and completes when
/// the user is back — finished or abandoned.
///
/// The gate is opened only for the duration of the flow so the router keeps
/// onboarding unreachable the rest of the time.
Future<void> startAddWallet(BuildContext context) async {
  final gate = context.read<AddWalletGate>()..open();
  await context.push<void>(Routes.addWallet);
  gate.close();
}
