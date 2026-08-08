import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('es'), Locale('pt')];

  /// The conventional newborn programmer greeting
  ///
  /// In en, this message translates to:
  /// **'Maniva Wallet'**
  String get title;

  /// No description provided for @emailField.
  ///
  /// In en, this message translates to:
  /// **'Type your e-mail'**
  String get emailField;

  /// No description provided for @passwordField.
  ///
  /// In en, this message translates to:
  /// **'Type your password'**
  String get passwordField;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @siginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with google'**
  String get siginWithGoogle;

  /// No description provided for @siginWithFb.
  ///
  /// In en, this message translates to:
  /// **'Sign in with facebook'**
  String get siginWithFb;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get or;

  /// No description provided for @premios.
  ///
  /// In en, this message translates to:
  /// **'Earn rewards for every referral that opens an account'**
  String get premios;

  /// No description provided for @refer.
  ///
  /// In en, this message translates to:
  /// **'Refer friends'**
  String get refer;

  /// No description provided for @recarga.
  ///
  /// In en, this message translates to:
  /// **'Recharge cell'**
  String get recarga;

  /// No description provided for @cobrar.
  ///
  /// In en, this message translates to:
  /// **'Cash in'**
  String get cobrar;

  /// No description provided for @depositar.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get depositar;

  /// No description provided for @emprestimos.
  ///
  /// In en, this message translates to:
  /// **'Lend'**
  String get emprestimos;

  /// No description provided for @transferir.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferir;

  /// No description provided for @limits.
  ///
  /// In en, this message translates to:
  /// **'Limits'**
  String get limits;

  /// No description provided for @pagar.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pagar;

  /// No description provided for @bloquear.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get bloquear;

  /// No description provided for @glogin.
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get glogin;

  /// No description provided for @alogin.
  ///
  /// In en, this message translates to:
  /// **'Anonimous Login'**
  String get alogin;

  /// No description provided for @anonimus.
  ///
  /// In en, this message translates to:
  /// **'Anonimous'**
  String get anonimus;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet #'**
  String get wallet;

  /// No description provided for @saldo.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get saldo;

  /// No description provided for @saldoUltimoMes.
  ///
  /// In en, this message translates to:
  /// **'Last Month Balance'**
  String get saldoUltimoMes;

  /// No description provided for @ultimaTransacao.
  ///
  /// In en, this message translates to:
  /// **'Click here to see last transactions details'**
  String get ultimaTransacao;

  /// No description provided for @copiar.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get copiar;

  /// No description provided for @continuar.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continuar;

  /// No description provided for @mensagem_invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get mensagem_invalid_email;

  /// No description provided for @mensagem_invalid_password.
  ///
  /// In en, this message translates to:
  /// **'Invalid Password. Password must not be least than 8 chars'**
  String get mensagem_invalid_password;

  /// No description provided for @mensagem_user_exists.
  ///
  /// In en, this message translates to:
  /// **'User already exist'**
  String get mensagem_user_exists;

  /// No description provided for @user_created_successfully.
  ///
  /// In en, this message translates to:
  /// **'User created'**
  String get user_created_successfully;

  /// No description provided for @mensagem_user_not_found.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get mensagem_user_not_found;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @sendTransaction.
  ///
  /// In en, this message translates to:
  /// **'Send new Transaction'**
  String get sendTransaction;

  /// No description provided for @receiveTransactions.
  ///
  /// In en, this message translates to:
  /// **'Your Rootstock Address'**
  String get receiveTransactions;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @txSent.
  ///
  /// In en, this message translates to:
  /// **'New transaction sent'**
  String get txSent;

  /// No description provided for @txReceived.
  ///
  /// In en, this message translates to:
  /// **'New transaction received'**
  String get txReceived;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get amount;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination address'**
  String get destination;

  /// No description provided for @copiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Copied to the clipboard'**
  String get copiedMessage;

  /// No description provided for @configureAccount.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get configureAccount;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @exitWebMessage.
  ///
  /// In en, this message translates to:
  /// **'Close this browser tab to exit'**
  String get exitWebMessage;

  /// No description provided for @createNewWallet.
  ///
  /// In en, this message translates to:
  /// **'Create New Wallet'**
  String get createNewWallet;

  /// No description provided for @restoreWallet.
  ///
  /// In en, this message translates to:
  /// **'Restore Wallet with Seed Phrase'**
  String get restoreWallet;

  /// No description provided for @restoreWalletWithPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Restore Wallet with Private Key'**
  String get restoreWalletWithPrivateKey;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @accountOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Overview'**
  String get accountOverviewTitle;

  /// No description provided for @bitcoinLabel.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin'**
  String get bitcoinLabel;

  /// No description provided for @rootstockLabel.
  ///
  /// In en, this message translates to:
  /// **'Rootstock'**
  String get rootstockLabel;

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// No description provided for @grandTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Grand total'**
  String get grandTotalLabel;

  /// No description provided for @mainnetBannerConfigured.
  ///
  /// In en, this message translates to:
  /// **'MAINNET — real funds, transactions are irreversible'**
  String get mainnetBannerConfigured;

  /// No description provided for @mainnetBannerNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'MAINNET selected but not configured — add ROOTSTOCK_NODE_MAIN / BITCOIN_NODE_MAIN / TOKENS_MAIN to .env'**
  String get mainnetBannerNotConfigured;

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountLabel;

  /// No description provided for @walletsLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get walletsLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @networkLabel.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get networkLabel;

  /// No description provided for @aboutLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutLabel;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersionLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @systemDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefaultLabel;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @switchToMainnetTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to Mainnet?'**
  String get switchToMainnetTitle;

  /// No description provided for @switchToMainnetBody.
  ///
  /// In en, this message translates to:
  /// **'Mainnet uses real BTC/RBTC. Transactions are irreversible — double-check addresses and amounts before sending. Make sure mainnet RPC endpoints are configured before relying on balances shown here.'**
  String get switchToMainnetBody;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @switchToMainnetButton.
  ///
  /// In en, this message translates to:
  /// **'Switch to Mainnet'**
  String get switchToMainnetButton;

  /// No description provided for @testnetLabel.
  ///
  /// In en, this message translates to:
  /// **'Testnet'**
  String get testnetLabel;

  /// No description provided for @mainnetLabel.
  ///
  /// In en, this message translates to:
  /// **'Mainnet'**
  String get mainnetLabel;

  /// No description provided for @customNodeUrlsLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom node URLs ({network})'**
  String customNodeUrlsLabel(String network);

  /// No description provided for @customNodeUrlsHint.
  ///
  /// In en, this message translates to:
  /// **'Override the default node/API endpoints for the currently selected network. Leave a field empty to use the app default.'**
  String get customNodeUrlsHint;

  /// No description provided for @bitcoinNodeUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin RPC node URL'**
  String get bitcoinNodeUrlLabel;

  /// No description provided for @bitcoinEsploraUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin Esplora API URL'**
  String get bitcoinEsploraUrlLabel;

  /// No description provided for @rootstockNodeUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Rootstock RPC node URL'**
  String get rootstockNodeUrlLabel;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @resetToDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefaultLabel;

  /// No description provided for @nodeUrlSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Node URL saved'**
  String get nodeUrlSavedMessage;

  /// No description provided for @nodeUrlResetMessage.
  ///
  /// In en, this message translates to:
  /// **'Reverted to default node URL'**
  String get nodeUrlResetMessage;

  /// No description provided for @invalidUrlMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid http(s) URL'**
  String get invalidUrlMessage;

  /// No description provided for @saveNodeUrlsButton.
  ///
  /// In en, this message translates to:
  /// **'Save node settings'**
  String get saveNodeUrlsButton;

  /// No description provided for @nodeUrlsSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Node settings saved'**
  String get nodeUrlsSavedMessage;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @receivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get receivedLabel;

  /// No description provided for @sentLabel.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sentLabel;

  /// No description provided for @atTheTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'At the time'**
  String get atTheTimeLabel;

  /// No description provided for @nowLabel.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get nowLabel;

  /// No description provided for @networkTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'{network} transactions'**
  String networkTransactionsTitle(String network);

  /// No description provided for @faq1Q.
  ///
  /// In en, this message translates to:
  /// **'What is Rootstock (RSK)?'**
  String get faq1Q;

  /// No description provided for @faq1A.
  ///
  /// In en, this message translates to:
  /// **'Rootstock is a smart contract platform secured by the Bitcoin network through merge-mining. RBTC, the coin used to pay for transactions on Rootstock, is pegged 1:1 with BTC.'**
  String get faq1A;

  /// No description provided for @faq2Q.
  ///
  /// In en, this message translates to:
  /// **'How do I send Bitcoin or Rootstock funds?'**
  String get faq2Q;

  /// No description provided for @faq2A.
  ///
  /// In en, this message translates to:
  /// **'Open your wallet, pick the Bitcoin or Rootstock section, tap Send, then enter the destination address and amount. You can use the Max button to send your full balance minus the estimated network fee.'**
  String get faq2A;

  /// No description provided for @faq3Q.
  ///
  /// In en, this message translates to:
  /// **'How does the BTC ↔ RBTC peg work?'**
  String get faq3Q;

  /// No description provided for @faq3A.
  ///
  /// In en, this message translates to:
  /// **'The powpeg protocol lets you move BTC into Rootstock (peg-in) and back out to Bitcoin (peg-out). Both your Bitcoin and Rootstock accounts are derived from the same private key, so they are always available side by side in this wallet.'**
  String get faq3A;

  /// No description provided for @faq4Q.
  ///
  /// In en, this message translates to:
  /// **'Where are my keys stored?'**
  String get faq4Q;

  /// No description provided for @faq4A.
  ///
  /// In en, this message translates to:
  /// **'Your private key and seed phrase are stored only on this device. Nobody else, including the app\'s developers, has access to them — write your seed phrase down and keep it safe, since it cannot be recovered if lost.'**
  String get faq4A;

  /// No description provided for @faq5Q.
  ///
  /// In en, this message translates to:
  /// **'What tokens are supported on Rootstock?'**
  String get faq5Q;

  /// No description provided for @faq5A.
  ///
  /// In en, this message translates to:
  /// **'Alongside RBTC, this wallet shows your balances of RIF, USDRIF, DOC, RIFPRO and tBRZ tokens.'**
  String get faq5A;

  /// No description provided for @walletSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet Security'**
  String get walletSecurityTitle;

  /// No description provided for @walletSecurityWarning.
  ///
  /// In en, this message translates to:
  /// **'This screen controls the funds in this wallet. Never share your private key or WIF with anyone, and make sure no one is watching your screen.'**
  String get walletSecurityWarning;

  /// No description provided for @privateKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get privateKeyLabel;

  /// No description provided for @bitcoinWifLabel.
  ///
  /// In en, this message translates to:
  /// **'Bitcoin Private Key (WIF)'**
  String get bitcoinWifLabel;

  /// No description provided for @revealLabel.
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get revealLabel;

  /// No description provided for @hideLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideLabel;

  /// No description provided for @confirmSavedKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'I have securely saved my private key'**
  String get confirmSavedKeyLabel;

  /// No description provided for @deleteWalletButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Wallet'**
  String get deleteWalletButton;

  /// No description provided for @deleteWalletConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this wallet?'**
  String get deleteWalletConfirmTitle;

  /// No description provided for @deleteWalletConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the wallet from this device. This cannot be undone — make sure you\'ve saved your private key, since it\'s the only way to access these funds again.'**
  String get deleteWalletConfirmBody;

  /// No description provided for @deleteWalletConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteWalletConfirmButton;

  /// No description provided for @walletDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Wallet deleted'**
  String get walletDeletedMessage;

  /// No description provided for @walletDeleteFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete wallet. Please try again.'**
  String get walletDeleteFailedMessage;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
