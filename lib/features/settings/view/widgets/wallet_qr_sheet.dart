import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'secret_reveal_body.dart' show SettingsSecondaryButton;
import 'settings_palette.dart';

/// Bottom sheet with the wallet's public address as a QR code, for receiving
/// funds or pairing. The address is public, so unlike the private-key export
/// there is no PIN gate or screen protection.
Future<void> showWalletQrSheet(
  BuildContext context, {
  required String address,
  required VoidCallback onCopy,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: SettingsPalette.cardMuted,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _WalletQrSheet(address: address, onCopy: onCopy),
  );
}

class _WalletQrSheet extends StatelessWidget {
  const _WalletQrSheet({required this.address, required this.onCopy});

  final String address;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Wallet Address',
              style: TextStyle(
                color: SettingsPalette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: address,
                size: 200,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              address,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SettingsPalette.textSecondary,
                fontSize: 13,
                height: 1.5,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 16),
            SettingsSecondaryButton(
              label: 'Copy Address',
              icon: Icons.copy_rounded,
              onPressed: () {
                onCopy();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
