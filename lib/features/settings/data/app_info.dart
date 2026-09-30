/// Build identity shown on Help & About. Release pipelines stamp these with
/// `--dart-define=APP_VERSION=… --dart-define=APP_BUILD=…`; the defaults
/// mirror `version:` in pubspec.yaml so local runs show something sensible.
abstract final class AppInfo {
  static const version = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.1.0',
  );
  static const build = String.fromEnvironment(
    'APP_BUILD',
    defaultValue: '1',
  );
}
