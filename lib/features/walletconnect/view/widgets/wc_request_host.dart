import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/wallet_connect_repository.dart';
import '../../view_model/request_review_cubit.dart';
import '../../view_model/request_review_state.dart';
import 'review_request_sheet.dart';

/// Wraps the whole app so a request from a connected dApp is reviewed on
/// top of whatever screen the user is on. Owns the [RequestReviewCubit]
/// and keeps exactly one sheet open while requests are pending; swapping
/// between queued requests happens inside that sheet.
class WcRequestHost extends StatefulWidget {
  const WcRequestHost({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<WcRequestHost> createState() => _WcRequestHostState();
}

class _WcRequestHostState extends State<WcRequestHost> {
  late final RequestReviewCubit _cubit;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    _cubit = RequestReviewCubit(
      repository: context.read<WalletConnectRepository>(),
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _openSheet() {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null || _sheetOpen) return;
    _sheetOpen = true;
    showModalBottomSheet<void>(
      context: navigatorContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: _cubit,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: const _QueuedRequestSheet(),
        ),
      ),
    ).then((_) {
      _sheetOpen = false;
      // Swiped away / barrier tap while still reviewing: that's a rejection.
      if (_cubit.state is RequestReviewReviewing) _cubit.reject();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<RequestReviewCubit, RequestReviewState>(
        listener: (context, state) {
          // Only `reviewing` opens a sheet. Opening on `submitting` too would
          // spawn a sheet right after a swipe-dismiss (whose reject() goes
          // submitting -> idle) that nothing ever closes: a stuck scrim.
          if (state is RequestReviewReviewing) _openSheet();
        },
        child: widget.child,
      ),
    );
  }
}

class _QueuedRequestSheet extends StatelessWidget {
  const _QueuedRequestSheet();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RequestReviewCubit>();
    return BlocConsumer<RequestReviewCubit, RequestReviewState>(
      listenWhen: (previous, current) => current is RequestReviewIdle,
      listener: (context, state) {
        final route = ModalRoute.of(context);
        if (route != null && route.isCurrent) Navigator.of(context).pop();
      },
      builder: (context, state) {
        final (request, busy, queued) = switch (state) {
          RequestReviewReviewing(:final request, :final queued) =>
            (request, false, queued),
          RequestReviewSubmitting(:final request) => (request, true, 0),
          RequestReviewIdle() => (null, false, 0),
        };
        if (request == null) return const SizedBox.shrink();
        return buildRequestSheet(
          request,
          busy: busy,
          queued: queued,
          onDecision: (decision) => decision.approved
              ? cubit.approve(approvalCap: decision.approvalCap)
              : cubit.reject(),
        );
      },
    );
  }
}
