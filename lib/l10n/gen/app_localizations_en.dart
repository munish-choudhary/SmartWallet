// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Lexor Pocket';

  @override
  String get splashTagline => 'Your Keys. Your Crypto.';

  @override
  String get welcomeEyebrow => 'Non-Custodial • Multi-Chain';

  @override
  String get welcomeHeadline => 'Your Keys.\nYour Crypto.';

  @override
  String get welcomeSubtitle =>
      'Buy, store, swap, and manage your digital assets with institutional-grade security and zero compromise.';

  @override
  String get welcomeGetStarted => 'Get Started';

  @override
  String get welcomeTerms =>
      'By continuing, you agree to Lexor Pocket\'s Terms of Service and Privacy Notice.';

  @override
  String get setupChoiceTitle => 'Wallet Setup';

  @override
  String get setupChoiceHeadline => 'Get Started with Lexor Pocket';

  @override
  String get setupChoiceSubtitle =>
      'Choose how you\'d like to set up your wallet';

  @override
  String get setupChoiceCreateTitle => 'Create New Wallet';

  @override
  String get setupChoiceCreateBody =>
      'Generate a fresh multi-chain vault with a 12- or 24-word recovery phrase.';

  @override
  String get setupChoiceCreateBadge => 'Recommended';

  @override
  String get setupChoiceImportTitle => 'Import Existing Wallet';

  @override
  String get setupChoiceImportBody =>
      'Restore your funds using a secret recovery phrase or private key.';

  @override
  String get setupChoiceFooter =>
      'Non-custodial. Your keys are encrypted on this device.';

  @override
  String get pinCreateTitle => 'Create Passcode';

  @override
  String get pinCreateSubtitle =>
      'Set a 6-digit passcode to unlock your vault and authorize transactions.';

  @override
  String get pinConfirmTitle => 'Confirm Passcode';

  @override
  String get pinConfirmSubtitle => 'Re-enter your 6-digit passcode to verify.';

  @override
  String pinDigitsEntered(int count, int total) {
    return '$count of $total digits entered';
  }

  @override
  String get pinTrivialError =>
      'That passcode is too easy to guess. Avoid repeated or sequential digits.';

  @override
  String get pinMismatchError => 'Passcodes don\'t match. Try again.';

  @override
  String get pinMismatchTooMany => 'Too many mismatches — let\'s start over.';

  @override
  String get pinNeverShare => 'Never share your passcode with anyone.';

  @override
  String get biometricsTitle => 'Enable Quick Unlock';

  @override
  String get biometricsSubtitle =>
      'Use Face ID or fingerprint to unlock your vault faster. You can change this later in Settings.';

  @override
  String get biometricsEnable => 'Enable Biometrics';

  @override
  String get biometricsSkip => 'Skip for now';

  @override
  String get backupWarningTitle => 'Back Up Your Wallet';

  @override
  String backupWarningBody(int count) {
    return 'In the next step you\'ll see your $count-word Secret Recovery Phrase. It\'s the only way to recover your funds if you lose access.';
  }

  @override
  String get backupWarningItem1Title => 'Never share your phrase';

  @override
  String get backupWarningItem1Body =>
      'Anyone with your recovery phrase can steal all your funds instantly. We will never ask for it.';

  @override
  String get backupWarningItem2Title => 'Store it safely offline';

  @override
  String get backupWarningItem2Body =>
      'Write it down on paper. Do not take screenshots or store it in cloud backups.';

  @override
  String get backupWarningItem3Title => 'We cannot recover it';

  @override
  String get backupWarningItem3Body =>
      'Lexor Pocket is non-custodial. If you lose this phrase, your assets are unrecoverable.';

  @override
  String get backupWarningContinue => 'Continue to Phrase';

  @override
  String get recoveryPhraseTitle => 'Recovery Phrase';

  @override
  String get recoveryPhraseHeadline => 'Your Recovery Phrase';

  @override
  String recoveryPhraseSubtitle(int count) {
    return 'Write down these $count words in order. Never share them with anyone.';
  }

  @override
  String get recoveryPhraseHide => 'Hide Words';

  @override
  String get recoveryPhraseReveal => 'Reveal Words';

  @override
  String get recoveryPhraseScreenWarning =>
      'Make sure no one is watching your screen';

  @override
  String get recoveryPhraseCopy => 'Copy to Clipboard';

  @override
  String get recoveryPhraseCopiedSnackbar =>
      'Copied — clipboard will clear automatically in 60 seconds';

  @override
  String get recoveryPhraseScreenshotWarningTitle => 'Do not take screenshots';

  @override
  String get recoveryPhraseScreenshotWarningBody =>
      'Digital photos and cloud uploads are vulnerable to remote extraction.';

  @override
  String get recoveryPhraseSaved => 'I\'ve Saved My Phrase';

  @override
  String get recoveryPhraseLeaveDialogTitle => 'Leave without saving?';

  @override
  String get recoveryPhraseLeaveDialogBody =>
      'Leaving now will discard this wallet. You\'ll need to start over.';

  @override
  String get recoveryPhraseLeaveDialogConfirm => 'Discard';

  @override
  String get recoveryPhraseLeaveDialogCancel => 'Stay';

  @override
  String get verifyPhraseTitle => 'Verify Phrase';

  @override
  String get verifyPhraseHeadline => 'Verify Recovery Phrase';

  @override
  String get verifyPhraseSubtitle =>
      'Tap the words that belong at each position.';

  @override
  String verifyPhraseWordPrompt(int index) {
    return 'Select word #$index';
  }

  @override
  String verifyPhraseProgress(int done, int total) {
    return '$done of $total verified';
  }

  @override
  String get verifyPhraseConfirm => 'Confirm & Complete';

  @override
  String get verifyPhraseShowAgain => 'Need to see the words again?';

  @override
  String get verifyPhraseWrongWord => 'That\'s not the right word — try again.';

  @override
  String get creationSuccessTitle => 'Wallet Created!';

  @override
  String get creationSuccessSubtitle =>
      'Your self-custodial vault is encrypted and ready to use.';

  @override
  String get creationSuccessGoToWallet => 'Go to Wallet';

  @override
  String get importMethodTitle => 'Choose Import Method';

  @override
  String get importMethodSubtitle =>
      'Restore your wallet from an existing seed phrase or a raw private key.';

  @override
  String get importMethodPhraseTab => 'Secret Phrase';

  @override
  String get importMethodKeyTab => 'Private Key';

  @override
  String get importMethodContinuePhrase => 'Continue with Phrase';

  @override
  String get importMethodContinueKey => 'Continue with Key';

  @override
  String get importMethodPhraseCardTitle => 'Secret Recovery Phrase';

  @override
  String get importMethodPhraseCardBody =>
      '12 or 24 mnemonic words (BIP-39 standard).';

  @override
  String get importMethodKeyCardTitle => 'Raw Private Key';

  @override
  String get importMethodKeyCardBody =>
      '64-character hexadecimal key for a single account.';

  @override
  String get importPhraseTitle => 'Enter Recovery Phrase';

  @override
  String get importPhraseSubtitle =>
      'Type or paste your mnemonic seed in exact order.';

  @override
  String get importPhrase12Words => '12 Words';

  @override
  String get importPhrase24Words => '24 Words';

  @override
  String get importPhrasePasteAll => 'Paste All';

  @override
  String get importPhraseClear => 'Clear phrase';

  @override
  String importPhraseWordsValid(int valid, int total) {
    return '$valid / $total words valid';
  }

  @override
  String get importPhraseChecksumValid => 'Checksum verified';

  @override
  String get importPhraseChecksumValidBody =>
      'Valid BIP-39 mnemonic pattern confirmed.';

  @override
  String get importPhraseInvalidWord => 'Not a valid recovery word';

  @override
  String get importWallet => 'Import Wallet';

  @override
  String get importKeyTitle => 'Enter Private Key';

  @override
  String get importKeySubtitle =>
      'Input your raw private key to import this account.';

  @override
  String get importKeyNetwork => 'Target Network';

  @override
  String get importKeyHexLabel => 'Hex Key (256-bit)';

  @override
  String get importKeyShow => 'Show';

  @override
  String get importKeyHide => 'Hide';

  @override
  String get importKeyFormatValid => 'Format valid';

  @override
  String get importKeyPaste => 'Paste Clipboard';

  @override
  String get importKeyScanQr => 'Scan QR Code';

  @override
  String get importKeyScanQrComingSoon => 'QR scanning coming soon';

  @override
  String get importKeyWarningTitle => 'Security Warning';

  @override
  String get importKeyWarningBody =>
      'Never paste private keys on untrusted devices. Private keys grant full control over linked funds.';

  @override
  String get networkEthereum => 'Ethereum Mainnet (EVM)';

  @override
  String get networkSmartChain => 'BNB Chain (EVM)';

  @override
  String get networkPolygon => 'Polygon (EVM)';

  @override
  String get networkArbitrum => 'Arbitrum (EVM)';

  @override
  String get networkBase => 'Base (EVM)';

  @override
  String get networkSolana => 'Solana';

  @override
  String get networkTron => 'Tron';

  @override
  String get networkBitcoin => 'Bitcoin';

  @override
  String get importingTitle => 'Importing Vault';

  @override
  String get importingBody => 'Encrypting and setting up your wallet…';

  @override
  String get importSuccessTitle => 'Wallet Imported!';

  @override
  String get importSuccessSubtitle =>
      'Your wallet has been restored and encrypted on this device.';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonGenericError => 'Something went wrong. Please try again.';
}
