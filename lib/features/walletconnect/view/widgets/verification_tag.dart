import 'package:flutter/material.dart';

import '../../../../core/design_system/lexor_card.dart';
import '../../../../core/design_system/lexor_palette.dart';
import '../../data/models/wc_dapp.dart';

/// "VERIFIED DOMAIN" / "UNVERIFIED DOMAIN" / "FLAGGED AS MALICIOUS".
class VerificationTag extends StatelessWidget {
  const VerificationTag(this.verification, {super.key});

  final WcVerification verification;

  @override
  Widget build(BuildContext context) {
    return switch (verification) {
      WcVerification.verified => const LexorTag(
          'Verified domain',
          icon: Icons.verified_user_rounded,
          color: LexorPalette.accentMuted,
        ),
      WcVerification.unverified => const LexorTag(
          'Unverified domain',
          icon: Icons.help_outline_rounded,
          color: LexorPalette.caution,
          background: LexorPalette.cautionFill,
        ),
      WcVerification.flagged => const LexorTag(
          'Flagged as malicious',
          icon: Icons.gpp_bad_rounded,
          color: LexorPalette.danger,
          background: LexorPalette.dangerFill,
        ),
    };
  }
}
