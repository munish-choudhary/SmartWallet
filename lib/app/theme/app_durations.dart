/// Animation duration/curve tokens shared by every screen transition and
/// micro-interaction, per CLAUDE.md's "no hardcoded sizes" spirit applied
/// to timing too.
abstract final class AppDurations {
  static const instant = Duration(milliseconds: 120);
  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 350);
  static const slow = Duration(milliseconds: 600);
  static const splash = Duration(milliseconds: 1400);

  /// Page transition duration used by go_router's fade+slide builder.
  static const pageTransition = Duration(milliseconds: 300);

  static const staggerStep = Duration(milliseconds: 60);
}
