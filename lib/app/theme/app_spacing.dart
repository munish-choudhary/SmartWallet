/// Spacing tokens (4px baseline grid), per CLAUDE.md's "no hardcoded sizes"
/// rule.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 48.0;

  /// Standard horizontal screen gutter.
  static const screenPadding = 20.0;
}

/// Corner radius tokens.
abstract final class AppRadii {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const pill = 999.0;
}
