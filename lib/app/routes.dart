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

  /// Add-wallet flow only: asks for the existing PIN (every wallet in the
  /// vault shares one PIN) instead of creating a new one.
  static const verifyPin = '$onboarding/verify-pin';
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

  static const securitySettings = '/settings/security';
  static const autoLock = '$securitySettings/auto-lock';
  static const showRecoveryPhrase = '$securitySettings/recovery-phrase';
  static const exportPrivateKey = '$securitySettings/export-private-key';
  static const balancePrivacy = '$securitySettings/balance-privacy';

  static const helpAbout = '/settings/help-about';

  /// Settings → Networks. Only "add custom network" exists so far.
  static const addCustomNetwork = '/settings/networks/add';

  /// Home → profile: the active wallet's identity, keys and tools.
  static const walletDetails = '/wallet';
  static const renameWallet = '$walletDetails/rename';

  /// Every wallet on the device, with switching.
  static const wallets = '$walletDetails/all';

  /// Create/import another wallet. Lives in the onboarding shell (it
  /// reuses those screens) but is reachable with a wallet present.
  static const addWallet = '/wallets/add';

  /// WalletConnect. Only the session topic (a public identifier) ever
  /// appears in a path — never the pairing link, which carries a key.
  static const walletConnect = '/walletconnect';
  static const walletConnectPairing = '$walletConnect/pairing';
  static const walletConnectConnected = '$walletConnect/connected';

  /// Returns the scanned pairing link by popping with it (never as a param).
  static const walletConnectScan = '$walletConnect/scan';
  static const walletConnectSession = '$walletConnect/session';
  static String walletConnectSessionPath(String topic) =>
      '$walletConnectSession/${Uri.encodeComponent(topic)}';

  static const buySell = '/buy-sell';
  static const manageTokens = '/portfolio/manage-tokens';
  static const addCustomToken = '$manageTokens/add';
  static const priceAlerts = '/alerts';
  static const notifications = '/notifications';

  /// dApp browser: `/dapps` is the discovery screen, `/dapps/browse?url=`
  /// the in-app web view.
  static const dapps = '/dapps';
  static const dappBrowse = '$dapps/browse';
  static String dappBrowsePath(String url) =>
      '$dappBrowse?url=${Uri.encodeQueryComponent(url)}';

  /// AI assistant chat. `?token=SYMBOL` (a public symbol) pre-fills the
  /// prompt when opened from a token page.
  static const aiAssistant = '/ai';
  static String aiAssistantPath({String? token}) =>
      token == null ? aiAssistant : '$aiAssistant?token=${Uri.encodeQueryComponent(token)}';
}
