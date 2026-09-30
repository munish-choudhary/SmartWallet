import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The app's display name
  ///
  /// In en, this message translates to:
  /// **'Lexor Pocket'**
  String get appName;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your Keys. Your Crypto.'**
  String get splashTagline;

  /// No description provided for @welcomeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Non-Custodial • Multi-Chain'**
  String get welcomeEyebrow;

  /// No description provided for @welcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your Keys.\nYour Crypto.'**
  String get welcomeHeadline;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Buy, store, swap, and manage your digital assets with institutional-grade security and zero compromise.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get welcomeGetStarted;

  /// No description provided for @welcomeTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to Lexor Pocket\'s Terms of Service and Privacy Notice.'**
  String get welcomeTerms;

  /// No description provided for @setupChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet Setup'**
  String get setupChoiceTitle;

  /// No description provided for @setupChoiceHeadline.
  ///
  /// In en, this message translates to:
  /// **'Get Started with Lexor Pocket'**
  String get setupChoiceHeadline;

  /// No description provided for @setupChoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'d like to set up your wallet'**
  String get setupChoiceSubtitle;

  /// No description provided for @setupChoiceCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Wallet'**
  String get setupChoiceCreateTitle;

  /// No description provided for @setupChoiceCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Generate a fresh multi-chain vault with a 12- or 24-word recovery phrase.'**
  String get setupChoiceCreateBody;

  /// No description provided for @setupChoiceCreateBadge.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get setupChoiceCreateBadge;

  /// No description provided for @setupChoiceImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Existing Wallet'**
  String get setupChoiceImportTitle;

  /// No description provided for @setupChoiceImportBody.
  ///
  /// In en, this message translates to:
  /// **'Restore your funds using a secret recovery phrase or private key.'**
  String get setupChoiceImportBody;

  /// No description provided for @setupChoiceFooter.
  ///
  /// In en, this message translates to:
  /// **'Non-custodial. Your keys are encrypted on this device.'**
  String get setupChoiceFooter;

  /// No description provided for @pinCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Passcode'**
  String get pinCreateTitle;

  /// No description provided for @pinCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a 6-digit passcode to unlock your vault and authorize transactions.'**
  String get pinCreateSubtitle;

  /// No description provided for @pinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Passcode'**
  String get pinConfirmTitle;

  /// No description provided for @pinConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your 6-digit passcode to verify.'**
  String get pinConfirmSubtitle;

  /// No description provided for @pinDigitsEntered.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} digits entered'**
  String pinDigitsEntered(int count, int total);

  /// No description provided for @pinTrivialError.
  ///
  /// In en, this message translates to:
  /// **'That passcode is too easy to guess. Avoid repeated or sequential digits.'**
  String get pinTrivialError;

  /// No description provided for @pinMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Passcodes don\'t match. Try again.'**
  String get pinMismatchError;

  /// No description provided for @pinVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Passcode'**
  String get pinVerifyTitle;

  /// No description provided for @pinVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your current passcode to add another wallet.'**
  String get pinVerifySubtitle;

  /// No description provided for @pinWrongError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect passcode. Try again.'**
  String get pinWrongError;

  /// No description provided for @pinLockedOutError.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get pinLockedOutError;

  /// No description provided for @pinMismatchTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many mismatches — let\'s start over.'**
  String get pinMismatchTooMany;

  /// No description provided for @pinNeverShare.
  ///
  /// In en, this message translates to:
  /// **'Never share your passcode with anyone.'**
  String get pinNeverShare;

  /// No description provided for @biometricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Quick Unlock'**
  String get biometricsTitle;

  /// No description provided for @biometricsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID or fingerprint to unlock your vault faster. You can change this later in Settings.'**
  String get biometricsSubtitle;

  /// No description provided for @biometricsEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometrics'**
  String get biometricsEnable;

  /// No description provided for @biometricsSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get biometricsSkip;

  /// No description provided for @backupWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Back Up Your Wallet'**
  String get backupWarningTitle;

  /// No description provided for @backupWarningBody.
  ///
  /// In en, this message translates to:
  /// **'In the next step you\'ll see your {count}-word Secret Recovery Phrase. It\'s the only way to recover your funds if you lose access.'**
  String backupWarningBody(int count);

  /// No description provided for @backupWarningItem1Title.
  ///
  /// In en, this message translates to:
  /// **'Never share your phrase'**
  String get backupWarningItem1Title;

  /// No description provided for @backupWarningItem1Body.
  ///
  /// In en, this message translates to:
  /// **'Anyone with your recovery phrase can steal all your funds instantly. We will never ask for it.'**
  String get backupWarningItem1Body;

  /// No description provided for @backupWarningItem2Title.
  ///
  /// In en, this message translates to:
  /// **'Store it safely offline'**
  String get backupWarningItem2Title;

  /// No description provided for @backupWarningItem2Body.
  ///
  /// In en, this message translates to:
  /// **'Write it down on paper. Do not take screenshots or store it in cloud backups.'**
  String get backupWarningItem2Body;

  /// No description provided for @backupWarningItem3Title.
  ///
  /// In en, this message translates to:
  /// **'We cannot recover it'**
  String get backupWarningItem3Title;

  /// No description provided for @backupWarningItem3Body.
  ///
  /// In en, this message translates to:
  /// **'Lexor Pocket is non-custodial. If you lose this phrase, your assets are unrecoverable.'**
  String get backupWarningItem3Body;

  /// No description provided for @backupWarningContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to Phrase'**
  String get backupWarningContinue;

  /// No description provided for @recoveryPhraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery Phrase'**
  String get recoveryPhraseTitle;

  /// No description provided for @recoveryPhraseStepPill.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 3'**
  String get recoveryPhraseStepPill;

  /// No description provided for @recoveryPhrasePrivacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Private view active'**
  String get recoveryPhrasePrivacyLabel;

  /// No description provided for @recoveryPhraseHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your Recovery Phrase'**
  String get recoveryPhraseHeadline;

  /// No description provided for @recoveryPhraseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Write down these {count} words in order. Never share them with anyone.'**
  String recoveryPhraseSubtitle(int count);

  /// No description provided for @recoveryPhraseHide.
  ///
  /// In en, this message translates to:
  /// **'Hide Words'**
  String get recoveryPhraseHide;

  /// No description provided for @recoveryPhraseReveal.
  ///
  /// In en, this message translates to:
  /// **'Reveal Words'**
  String get recoveryPhraseReveal;

  /// No description provided for @recoveryPhraseScreenWarning.
  ///
  /// In en, this message translates to:
  /// **'Make sure no one is watching your screen'**
  String get recoveryPhraseScreenWarning;

  /// No description provided for @recoveryPhraseCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get recoveryPhraseCopy;

  /// No description provided for @recoveryPhraseCopiedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Copied — clipboard will clear automatically in 60 seconds'**
  String get recoveryPhraseCopiedSnackbar;

  /// No description provided for @recoveryPhraseScreenshotWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Do not take screenshots'**
  String get recoveryPhraseScreenshotWarningTitle;

  /// No description provided for @recoveryPhraseScreenshotWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Digital photos and cloud uploads are vulnerable to remote extraction.'**
  String get recoveryPhraseScreenshotWarningBody;

  /// No description provided for @recoveryPhraseSaved.
  ///
  /// In en, this message translates to:
  /// **'I\'ve Saved My Phrase'**
  String get recoveryPhraseSaved;

  /// No description provided for @recoveryPhraseLeaveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get recoveryPhraseLeaveDialogTitle;

  /// No description provided for @recoveryPhraseLeaveDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Leaving now will discard this wallet. You\'ll need to start over.'**
  String get recoveryPhraseLeaveDialogBody;

  /// No description provided for @recoveryPhraseLeaveDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get recoveryPhraseLeaveDialogConfirm;

  /// No description provided for @recoveryPhraseLeaveDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get recoveryPhraseLeaveDialogCancel;

  /// No description provided for @verifyPhraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Phrase'**
  String get verifyPhraseTitle;

  /// No description provided for @verifyPhraseStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyPhraseStepLabel;

  /// No description provided for @verifyPhraseHeadline.
  ///
  /// In en, this message translates to:
  /// **'Verify Recovery Phrase'**
  String get verifyPhraseHeadline;

  /// No description provided for @verifyPhraseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the words that belong at each position.'**
  String get verifyPhraseSubtitle;

  /// No description provided for @verifyPhraseWordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select word #{index}'**
  String verifyPhraseWordPrompt(int index);

  /// No description provided for @verifyPhraseProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} verified'**
  String verifyPhraseProgress(int done, int total);

  /// No description provided for @verifyPhraseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Complete'**
  String get verifyPhraseConfirm;

  /// No description provided for @verifyPhraseShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Need to see the words again?'**
  String get verifyPhraseShowAgain;

  /// No description provided for @verifyPhraseWrongWord.
  ///
  /// In en, this message translates to:
  /// **'That\'s not the right word — try again.'**
  String get verifyPhraseWrongWord;

  /// No description provided for @creationSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet Created!'**
  String get creationSuccessTitle;

  /// No description provided for @creationSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your self-custodial vault is encrypted and ready to use.'**
  String get creationSuccessSubtitle;

  /// No description provided for @creationSuccessGoToWallet.
  ///
  /// In en, this message translates to:
  /// **'Go to Wallet'**
  String get creationSuccessGoToWallet;

  /// No description provided for @importMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Import Method'**
  String get importMethodTitle;

  /// No description provided for @importMethodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore your wallet from an existing seed phrase or a raw private key.'**
  String get importMethodSubtitle;

  /// No description provided for @importMethodPhraseTab.
  ///
  /// In en, this message translates to:
  /// **'Secret Phrase'**
  String get importMethodPhraseTab;

  /// No description provided for @importMethodKeyTab.
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get importMethodKeyTab;

  /// No description provided for @importMethodContinuePhrase.
  ///
  /// In en, this message translates to:
  /// **'Continue with Phrase'**
  String get importMethodContinuePhrase;

  /// No description provided for @importMethodContinueKey.
  ///
  /// In en, this message translates to:
  /// **'Continue with Key'**
  String get importMethodContinueKey;

  /// No description provided for @importMethodPhraseCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Secret Recovery Phrase'**
  String get importMethodPhraseCardTitle;

  /// No description provided for @importMethodPhraseCardBody.
  ///
  /// In en, this message translates to:
  /// **'12 or 24 mnemonic words (BIP-39 standard).'**
  String get importMethodPhraseCardBody;

  /// No description provided for @importMethodKeyCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Raw Private Key'**
  String get importMethodKeyCardTitle;

  /// No description provided for @importMethodKeyCardBody.
  ///
  /// In en, this message translates to:
  /// **'64-character hexadecimal key for a single account.'**
  String get importMethodKeyCardBody;

  /// No description provided for @importPhraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Recovery Phrase'**
  String get importPhraseTitle;

  /// No description provided for @importPhraseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type or paste your mnemonic seed in exact order.'**
  String get importPhraseSubtitle;

  /// No description provided for @importPhrase12Words.
  ///
  /// In en, this message translates to:
  /// **'12 Words'**
  String get importPhrase12Words;

  /// No description provided for @importPhrase24Words.
  ///
  /// In en, this message translates to:
  /// **'24 Words'**
  String get importPhrase24Words;

  /// No description provided for @importPhrasePasteAll.
  ///
  /// In en, this message translates to:
  /// **'Paste All'**
  String get importPhrasePasteAll;

  /// No description provided for @importPhraseClear.
  ///
  /// In en, this message translates to:
  /// **'Clear phrase'**
  String get importPhraseClear;

  /// No description provided for @importPhraseWordsValid.
  ///
  /// In en, this message translates to:
  /// **'{valid} / {total} words valid'**
  String importPhraseWordsValid(int valid, int total);

  /// No description provided for @importPhraseChecksumValid.
  ///
  /// In en, this message translates to:
  /// **'Checksum verified'**
  String get importPhraseChecksumValid;

  /// No description provided for @importPhraseChecksumValidBody.
  ///
  /// In en, this message translates to:
  /// **'Valid BIP-39 mnemonic pattern confirmed.'**
  String get importPhraseChecksumValidBody;

  /// No description provided for @importPhraseInvalidWord.
  ///
  /// In en, this message translates to:
  /// **'Not a valid recovery word'**
  String get importPhraseInvalidWord;

  /// No description provided for @importWallet.
  ///
  /// In en, this message translates to:
  /// **'Import Wallet'**
  String get importWallet;

  /// No description provided for @importKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Private Key'**
  String get importKeyTitle;

  /// No description provided for @importKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Input your raw private key to import this account.'**
  String get importKeySubtitle;

  /// No description provided for @importKeyNetwork.
  ///
  /// In en, this message translates to:
  /// **'Target Network'**
  String get importKeyNetwork;

  /// No description provided for @importKeyHexLabel.
  ///
  /// In en, this message translates to:
  /// **'Hex Key (256-bit)'**
  String get importKeyHexLabel;

  /// No description provided for @importKeyShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get importKeyShow;

  /// No description provided for @importKeyHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get importKeyHide;

  /// No description provided for @importKeyFormatValid.
  ///
  /// In en, this message translates to:
  /// **'Format valid'**
  String get importKeyFormatValid;

  /// No description provided for @importKeyPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste Clipboard'**
  String get importKeyPaste;

  /// No description provided for @importKeyScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get importKeyScanQr;

  /// No description provided for @importKeyScanQrComingSoon.
  ///
  /// In en, this message translates to:
  /// **'QR scanning coming soon'**
  String get importKeyScanQrComingSoon;

  /// No description provided for @importKeyWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Warning'**
  String get importKeyWarningTitle;

  /// No description provided for @importKeyWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Never paste private keys on untrusted devices. Private keys grant full control over linked funds.'**
  String get importKeyWarningBody;

  /// No description provided for @networkEthereum.
  ///
  /// In en, this message translates to:
  /// **'Ethereum Mainnet (EVM)'**
  String get networkEthereum;

  /// No description provided for @networkSmartChain.
  ///
  /// In en, this message translates to:
  /// **'BNB Chain (EVM)'**
  String get networkSmartChain;

  /// No description provided for @networkPolygon.
  ///
  /// In en, this message translates to:
  /// **'Polygon (EVM)'**
  String get networkPolygon;

  /// No description provided for @networkArbitrum.
  ///
  /// In en, this message translates to:
  /// **'Arbitrum (EVM)'**
  String get networkArbitrum;

  /// No description provided for @networkBase.
  ///
  /// In en, this message translates to:
  /// **'Base (EVM)'**
  String get networkBase;

  /// No description provided for @networkSolana.
  ///
  /// In en, this message translates to:
  /// **'Solana'**
  String get networkSolana;

  /// No description provided for @networkTron.
  ///
  /// In en, this message translates to:
  /// **'Tron'**
  String get networkTron;

  /// No description provided for @networkBitcoin.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin'**
  String get networkBitcoin;

  /// No description provided for @importingTitle.
  ///
  /// In en, this message translates to:
  /// **'Importing Vault'**
  String get importingTitle;

  /// No description provided for @importingBody.
  ///
  /// In en, this message translates to:
  /// **'Encrypting and setting up your wallet…'**
  String get importingBody;

  /// No description provided for @importSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet Imported!'**
  String get importSuccessTitle;

  /// No description provided for @importSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your wallet has been restored and encrypted on this device.'**
  String get importSuccessSubtitle;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonGenericError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
