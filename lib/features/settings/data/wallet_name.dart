import 'package:flutter/widgets.dart' show StringCharacters;

/// Rules for the user-chosen wallet name, shared by the Rename Wallet
/// screen's cubit (live validation) and the repository (defence in depth).
abstract final class WalletName {
  static const maxLength = 32;

  /// Shown until the user picks a name.
  static const fallback = 'My Wallet';

  static const suggestions = [
    'Personal Vault',
    'Main Portfolio',
    'Trading Stash',
    'Degen DeFi',
    'Savings Cold',
    'Ledger 1',
  ];

  /// The form actually stored: surrounding whitespace never counts.
  static String normalize(String raw) => raw.trim();

  /// Length in user-perceived characters, so an emoji counts as one and
  /// matches what the text field's length limiter enforces.
  static int lengthOf(String raw) => raw.characters.length;

  static bool isValid(String raw) {
    final length = lengthOf(normalize(raw));
    return length >= 1 && length <= maxLength;
  }
}
