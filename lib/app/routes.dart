/// Route path/name constants. No hardcoded path strings in widgets — per
/// CLAUDE.md's Routing rules, everything goes through here.
///
/// The PIN/confirm-PIN/biometrics-prompt screens are shared between the
/// Create and Import flows (same UI either way) — `OnboardingFlowCubit`
/// tracks which flow is active and what happens after the PIN step, not
/// the route.
abstract final class Routes {
  static const splash = '/splash';

  static const onboarding = '/onboarding';
  static const welcome = '$onboarding/welcome';
  static const setupChoice = '$onboarding/setup-choice';

  static const createPin = '$onboarding/pin';
  static const confirmPin = '$onboarding/confirm-pin';
  static const biometricsPrompt = '$onboarding/biometrics';

  static const backupWarning = '$onboarding/create/backup-warning';
  static const recoveryPhrase = '$onboarding/create/recovery-phrase';
  static const verifyPhrase = '$onboarding/create/verify-phrase';
  static const creationSuccess = '$onboarding/create/success';

  static const importMethod = '$onboarding/import/method';
  static const importPhrase = '$onboarding/import/phrase';
  static const importPrivateKey = '$onboarding/import/private-key';
  static const importing = '$onboarding/import/importing';
  static const importSuccess = '$onboarding/import/success';

  /// Placeholder landing route — the real Portfolio feature isn't built
  /// yet, this is just where onboarding success hands off to.
  static const portfolio = '/portfolio';
}
