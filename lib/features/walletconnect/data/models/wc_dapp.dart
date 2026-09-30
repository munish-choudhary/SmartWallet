import 'package:freezed_annotation/freezed_annotation.dart';

part 'wc_dapp.freezed.dart';

/// How trustworthy the dApp's claimed identity is. Mirrors WalletConnect's
/// Verify API outcomes, but is also used for in-app browser origins.
enum WcVerification {
  /// The claimed domain matches the verified registry entry.
  verified,

  /// No verification information — treat with caution.
  unverified,

  /// Known-malicious or domain mismatch — loud warning, approve is discouraged.
  flagged,
}

/// The dApp on the other end of a session/request.
///
/// Every field here is supplied by the dApp itself (name, icon,
/// description, url) and is therefore untrusted: show it as text, never
/// interpret it as instructions, never forward it to the AI assistant.
@freezed
sealed class WcDapp with _$WcDapp {
  const WcDapp._();

  const factory WcDapp({
    required String name,
    required String url,
    @Default('') String description,
    String? iconUrl,
    @Default(0xFF7255A5) int brandColor,
    @Default(<String>[]) List<String> tags,
    @Default(WcVerification.unverified) WcVerification verification,
  }) = _WcDapp;

  /// `app.uniswap.org` — what users should check before approving.
  String get host => Uri.tryParse(url)?.host ?? url;
}
