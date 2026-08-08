// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Maniva Wallet';

  @override
  String get emailField => 'Type your e-mail';

  @override
  String get passwordField => 'Type your password';

  @override
  String get login => 'Login';

  @override
  String get createAccount => 'Create account';

  @override
  String get siginWithGoogle => 'Sign in with google';

  @override
  String get siginWithFb => 'Sign in with facebook';

  @override
  String get or => 'Or';

  @override
  String get premios => 'Earn rewards for every referral that opens an account';

  @override
  String get refer => 'Refer friends';

  @override
  String get recarga => 'Recharge cell';

  @override
  String get cobrar => 'Cash in';

  @override
  String get depositar => 'Deposit';

  @override
  String get emprestimos => 'Lend';

  @override
  String get transferir => 'Transfer';

  @override
  String get limits => 'Limits';

  @override
  String get pagar => 'Pay';

  @override
  String get bloquear => 'Block';

  @override
  String get glogin => 'Login with Google';

  @override
  String get alogin => 'Anonimous Login';

  @override
  String get anonimus => 'Anonimous';

  @override
  String get wallet => 'Wallet #';

  @override
  String get saldo => 'Balance';

  @override
  String get saldoUltimoMes => 'Last Month Balance';

  @override
  String get ultimaTransacao => 'Click here to see last transactions details';

  @override
  String get copiar => 'Copy to clipboard';

  @override
  String get continuar => 'Continue';

  @override
  String get mensagem_invalid_email => 'Invalid email';

  @override
  String get mensagem_invalid_password =>
      'Invalid Password. Password must not be least than 8 chars';

  @override
  String get mensagem_user_exists => 'User already exist';

  @override
  String get user_created_successfully => 'User created';

  @override
  String get mensagem_user_not_found => 'User not found';

  @override
  String get send => 'Send';

  @override
  String get receive => 'Receive';

  @override
  String get sendTransaction => 'Send new Transaction';

  @override
  String get receiveTransactions => 'Your Rootstock Address';

  @override
  String get transactions => 'Transactions';

  @override
  String get txSent => 'New transaction sent';

  @override
  String get txReceived => 'New transaction received';

  @override
  String get amount => 'Enter amount';

  @override
  String get destination => 'Destination address';

  @override
  String get copiedMessage => 'Copied to the clipboard';

  @override
  String get configureAccount => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get help => 'Help';

  @override
  String get exit => 'Exit';

  @override
  String get exitWebMessage => 'Close this browser tab to exit';

  @override
  String get createNewWallet => 'Create New Wallet';

  @override
  String get restoreWallet => 'Restore Wallet with Seed Phrase';

  @override
  String get restoreWalletWithPrivateKey => 'Restore Wallet with Private Key';

  @override
  String get share => 'Share';

  @override
  String get paste => 'Paste';

  @override
  String get accountOverviewTitle => 'Account Overview';

  @override
  String get bitcoinLabel => 'Bitcoin';

  @override
  String get rootstockLabel => 'Rootstock';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get grandTotalLabel => 'Grand total';

  @override
  String get mainnetBannerConfigured => 'MAINNET — real funds, transactions are irreversible';

  @override
  String get mainnetBannerNotConfigured =>
      'MAINNET selected but not configured — add ROOTSTOCK_NODE_MAIN / BITCOIN_NODE_MAIN / TOKENS_MAIN to .env';

  @override
  String get accountLabel => 'Account';

  @override
  String get walletsLabel => 'Wallets';

  @override
  String get emailLabel => 'Email';

  @override
  String get networkLabel => 'Network';

  @override
  String get aboutLabel => 'About';

  @override
  String get appVersionLabel => 'App version';

  @override
  String get languageLabel => 'Language';

  @override
  String get systemDefaultLabel => 'System default';

  @override
  String get logOut => 'Log out';

  @override
  String get switchToMainnetTitle => 'Switch to Mainnet?';

  @override
  String get switchToMainnetBody =>
      'Mainnet uses real BTC/RBTC. Transactions are irreversible — double-check addresses and amounts before sending. Make sure mainnet RPC endpoints are configured before relying on balances shown here.';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get switchToMainnetButton => 'Switch to Mainnet';

  @override
  String get testnetLabel => 'Testnet';

  @override
  String get mainnetLabel => 'Mainnet';

  @override
  String customNodeUrlsLabel(String network) {
    return 'Custom node URLs ($network)';
  }

  @override
  String get customNodeUrlsHint =>
      'Override the default node/API endpoints for the currently selected network. Leave a field empty to use the app default.';

  @override
  String get bitcoinNodeUrlLabel => 'Bitcoin RPC node URL';

  @override
  String get bitcoinEsploraUrlLabel => 'Bitcoin Esplora API URL';

  @override
  String get rootstockNodeUrlLabel => 'Rootstock RPC node URL';

  @override
  String get saveLabel => 'Save';

  @override
  String get resetToDefaultLabel => 'Reset to default';

  @override
  String get nodeUrlSavedMessage => 'Node URL saved';

  @override
  String get nodeUrlResetMessage => 'Reverted to default node URL';

  @override
  String get invalidUrlMessage => 'Enter a valid http(s) URL';

  @override
  String get saveNodeUrlsButton => 'Save node settings';

  @override
  String get nodeUrlsSavedMessage => 'Node settings saved';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get receivedLabel => 'Received';

  @override
  String get sentLabel => 'Sent';

  @override
  String get atTheTimeLabel => 'At the time';

  @override
  String get nowLabel => 'Now';

  @override
  String networkTransactionsTitle(String network) {
    return '$network transactions';
  }

  @override
  String get faq1Q => 'What is Rootstock (RSK)?';

  @override
  String get faq1A =>
      'Rootstock is a smart contract platform secured by the Bitcoin network through merge-mining. RBTC, the coin used to pay for transactions on Rootstock, is pegged 1:1 with BTC.';

  @override
  String get faq2Q => 'How do I send Bitcoin or Rootstock funds?';

  @override
  String get faq2A =>
      'Open your wallet, pick the Bitcoin or Rootstock section, tap Send, then enter the destination address and amount. You can use the Max button to send your full balance minus the estimated network fee.';

  @override
  String get faq3Q => 'How does the BTC ↔ RBTC peg work?';

  @override
  String get faq3A =>
      'The powpeg protocol lets you move BTC into Rootstock (peg-in) and back out to Bitcoin (peg-out). Both your Bitcoin and Rootstock accounts are derived from the same private key, so they are always available side by side in this wallet.';

  @override
  String get faq4Q => 'Where are my keys stored?';

  @override
  String get faq4A =>
      'Your private key and seed phrase are stored only on this device. Nobody else, including the app\'s developers, has access to them — write your seed phrase down and keep it safe, since it cannot be recovered if lost.';

  @override
  String get faq5Q => 'What tokens are supported on Rootstock?';

  @override
  String get faq5A =>
      'Alongside RBTC, this wallet shows your balances of RIF, USDRIF, DOC, RIFPRO and tBRZ tokens.';

  @override
  String get walletSecurityTitle => 'Wallet Security';

  @override
  String get walletSecurityWarning =>
      'This screen controls the funds in this wallet. Never share your private key or WIF with anyone, and make sure no one is watching your screen.';

  @override
  String get privateKeyLabel => 'Private Key';

  @override
  String get bitcoinWifLabel => 'Bitcoin Private Key (WIF)';

  @override
  String get revealLabel => 'Reveal';

  @override
  String get hideLabel => 'Hide';

  @override
  String get confirmSavedKeyLabel => 'I have securely saved my private key';

  @override
  String get deleteWalletButton => 'Delete Wallet';

  @override
  String get deleteWalletConfirmTitle => 'Delete this wallet?';

  @override
  String get deleteWalletConfirmBody =>
      'This permanently removes the wallet from this device. This cannot be undone — make sure you\'ve saved your private key, since it\'s the only way to access these funds again.';

  @override
  String get deleteWalletConfirmButton => 'Delete';

  @override
  String get walletDeletedMessage => 'Wallet deleted';

  @override
  String get walletDeleteFailedMessage => 'Failed to delete wallet. Please try again.';
}
