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
  /// **'New tranasction sent'**
  String get txSent;

  /// No description provided for @txReceived.
  ///
  /// In en, this message translates to:
  /// **'New tranasction received'**
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
