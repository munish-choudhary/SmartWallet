import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/design_system/lexor_page_scaffold.dart';
import '../../../core/design_system/lexor_palette.dart';
import '../data/wc_pairing_uri.dart';

/// Scans a WalletConnect QR and pops with the pairing link (a `String`).
/// Only a structurally valid `wc:` link is accepted; anything else shows
/// a hint and scanning continues. The link carries a pairing key, so it is
/// returned via pop, never through a route parameter.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, this.scannerBuilder});

  /// Replaces the camera view (tests can't host one). Call `onLink` with
  /// raw scanned text.
  @visibleForTesting
  final Widget Function(BuildContext context, ValueChanged<String> onRaw)?
      scannerBuilder;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController? _controller;
  bool _done = false;
  bool _wrongCode = false;

  @override
  void initState() {
    super.initState();
    if (widget.scannerBuilder == null) {
      _controller = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onRaw(String raw) {
    if (_done) return;
    if (WcPairingUri.tryParse(raw) != null) {
      _done = true;
      context.pop(raw.trim());
    } else if (!_wrongCode) {
      setState(() => _wrongCode = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return LexorPageScaffold(
      title: 'Scan QR code',
      trailing: controller == null
          ? null
          : LexorHeaderAction(
              icon: Icons.flashlight_on_rounded,
              semanticLabel: 'Toggle flashlight',
              onPressed: controller.toggleTorch,
            ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.scannerBuilder?.call(context, _onRaw) ??
                        MobileScanner(
                          controller: controller,
                          onDetect: (capture) {
                            for (final code in capture.barcodes) {
                              final raw = code.rawValue;
                              if (raw != null) _onRaw(raw);
                            }
                          },
                          errorBuilder: (context, error) => const _CameraError(),
                        ),
                    IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _wrongCode
                                  ? LexorPalette.danger
                                  : LexorPalette.accent,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Text(
              _wrongCode
                  ? "That QR code isn't a WalletConnect link. Try the one "
                      'shown under "WalletConnect" on the app.'
                  : "Point the camera at the WalletConnect QR code on the "
                      "app's website.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _wrongCode
                    ? LexorPalette.danger
                    : LexorPalette.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: LexorPalette.cardSolid,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Camera unavailable. Allow camera access in Settings to scan, '
            'or paste the link instead.',
            textAlign: TextAlign.center,
            style: TextStyle(color: LexorPalette.textSecondary, height: 1.4),
          ),
        ),
      ),
    );
  }
}
