import 'package:flutter/material.dart';

import '../../../../core/design_system/dapp_icon.dart';
import '../../../../core/design_system/lexor_card.dart';
import '../../../../core/design_system/lexor_palette.dart';
import '../../data/models/wc_request.dart';
import 'verification_tag.dart';

/// Shared chrome of every review sheet: grab handle, title, where the
/// request came from (source badge), scrolling body and the Reject/Approve
/// pair. Keeping this in one place guarantees no signing sheet can omit
/// the source or the reject button.
class RequestSheetFrame extends StatelessWidget {
  const RequestSheetFrame({
    super.key,
    required this.request,
    required this.title,
    required this.body,
    required this.onReject,
    required this.onApprove,
    this.approveLabel = 'Approve',
    this.busy = false,
    this.queued = 0,
  });

  final WcRequest request;
  final String title;
  final Widget body;
  final VoidCallback onReject;

  /// Null disables the Approve button (e.g. a required field is empty).
  final VoidCallback? onApprove;
  final String approveLabel;
  final bool busy;
  final int queued;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      // A Material (not a DecoratedBox): widgets inside the body, like the
      // "Raw data" ExpansionTile, paint their ink on the nearest Material.
      child: Material(
        color: LexorPalette.sheet,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: LexorPalette.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: _Header(request: request, title: title, queued: queued),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: body,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _SheetButton(
                        label: 'Reject',
                        onPressed: busy ? null : onReject,
                        background: LexorPalette.chip,
                        foreground: LexorPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _SheetButton(
                        label: approveLabel,
                        onPressed: busy ? null : onApprove,
                        background: LexorPalette.accent,
                        foreground: LexorPalette.onAccent,
                        loading: busy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.request,
    required this.title,
    required this.queued,
  });

  final WcRequest request;
  final String title;
  final int queued;

  @override
  Widget build(BuildContext context) {
    final dapp = request.dapp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: LexorPalette.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (queued > 0)
              LexorTag(
                '+$queued waiting',
                background: LexorPalette.chip,
                color: LexorPalette.textSecondary,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            DappIcon(
              name: dapp.name,
              brandColor: dapp.brandColor,
              iconUrl: dapp.iconUrl,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dapp.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LexorPalette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    dapp.host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LexorPalette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            RequestSourceBadge(request: request),
            VerificationTag(dapp.verification),
          ],
        ),
      ],
    );
  }
}

/// "Uniswap via WalletConnect" / "Uniswap · in-app browser".
class RequestSourceBadge extends StatelessWidget {
  const RequestSourceBadge({super.key, required this.request});

  final WcRequest request;

  @override
  Widget build(BuildContext context) {
    final label = switch (request.origin) {
      WcRequestOrigin.walletConnect => '${request.dapp.name} via WalletConnect',
      WcRequestOrigin.inAppBrowser => '${request.dapp.name} · in-app browser',
    };
    return LexorTag(
      label,
      icon: request.origin == WcRequestOrigin.walletConnect
          ? Icons.link_rounded
          : Icons.public_rounded,
      color: LexorPalette.accent,
      background: const Color.fromRGBO(212, 238, 107, 0.12),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 52,
      child: Material(
        color: enabled || loading ? background : LexorPalette.chip,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: foreground,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: enabled ? foreground : LexorPalette.textDisabled,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Labelled value row used inside sheet cards.
class SheetRow extends StatelessWidget {
  const SheetRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = LexorPalette.textPrimary,
    this.mono = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: LexorPalette.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded inset container for grouped rows on a sheet.
class SheetCard extends StatelessWidget {
  const SheetCard({super.key, required this.child, this.label});

  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          LexorSectionLabel(label!),
          const SizedBox(height: 8),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: LexorPalette.cardSolid,
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
      ],
    );
  }
}
